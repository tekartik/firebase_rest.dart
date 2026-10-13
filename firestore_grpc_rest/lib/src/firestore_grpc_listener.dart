import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

/// Opens one listen connection authenticated with [token] (none when null):
/// a stream of snapshots that ends, with an error or not, with the
/// connection.
typedef GrpcListenConnect = Stream<DocumentSnapshot> Function(String? token);

/// The bearer token to listen with (null: unauthenticated), renewed first
/// when [forceRefresh].
typedef GrpcListenTokenGetter = Future<String?> Function({bool forceRefresh});

/// Keeps a document listen open across connection failures and auth
/// changes, emitting each new state of the document once.
///
/// - Every event of [authChanges] (a sign in, a sign out, another user)
///   reconnects with the token of the moment, unless it is the one of the
///   open connection.
/// - `unauthenticated`: the token was refused (expired): it is renewed and
///   the listen reconnects, once until a snapshot comes through, then the
///   error ends the stream.
/// - `permissionDenied` (the rules) ends the stream with the error, as the
///   native sdks do.
/// - Any other error, or the server closing the connection: reconnects after
///   a delay, from [initialRetryDelay] doubling up to [maxRetryDelay], back
///   to [initialRetryDelay] after a snapshot.
///
/// Cancelling the subscription closes the connection and leaves no timer.
class GrpcDocumentListener {
  /// Opens a connection.
  final GrpcListenConnect connect;

  /// The token to connect with.
  final GrpcListenTokenGetter getToken;

  /// Auth changes, a reconnection each.
  final Stream<Object?>? authChanges;

  /// The first retry delay.
  final Duration initialRetryDelay;

  /// The longest retry delay.
  final Duration maxRetryDelay;

  /// Called on listen, before connecting.
  final void Function()? onStart;

  /// Called once closed.
  final void Function()? onClose;

  /// Keeps a document listen open, see [stream].
  GrpcDocumentListener({
    required this.connect,
    required this.getToken,
    this.authChanges,
    this.initialRetryDelay = const Duration(seconds: 1),
    this.maxRetryDelay = const Duration(seconds: 60),
    this.onStart,
    this.onClose,
  });

  late final _controller = StreamController<DocumentSnapshot>(
    onListen: _start,
    onCancel: close,
  );

  /// The snapshots of the document, connecting on listen.
  Stream<DocumentSnapshot> get stream => _controller.stream;

  // Cancelled in close.
  // ignore: cancel_subscriptions
  StreamSubscription<Object?>? _authSubscription;
  // Cancelled when replaced, and in close.
  // ignore: cancel_subscriptions
  StreamSubscription<DocumentSnapshot>? _subscription;
  Timer? _retryTimer;
  var _closed = false;

  /// The latest connect request, older ones give up after resolving their
  /// token.
  var _request = 0;

  /// The current connection, the callbacks of older ones are ignored.
  var _connection = 0;

  /// The token of the current connection.
  String? _token;

  late var _retryDelay = initialRetryDelay;

  /// True after a renewal following `unauthenticated`, until a snapshot.
  var _tokenRenewed = false;

  /// Last emitted snapshot state, to skip duplicates (the server may send
  /// the same delete/change more than once, and a reconnect re-emits the
  /// current state).
  bool? _lastExists;
  Timestamp? _lastUpdateTime;

  /// The number of connections opened so far.
  var connectCount = 0;

  /// True once closed.
  bool get isClosed => _closed;

  void _start() {
    onStart?.call();
    _authSubscription = authChanges?.listen((_) {
      if (_closed) {
        return;
      }
      _retryDelay = initialRetryDelay;
      _tokenRenewed = false;
      unawaited(_connect(ifTokenChanged: true));
    });
    unawaited(_connect());
  }

  Future<void> _connect({
    bool forceRefresh = false,
    bool ifTokenChanged = false,
  }) async {
    if (_closed) {
      return;
    }
    var request = ++_request;
    String? token;
    try {
      token = await getToken(forceRefresh: forceRefresh);
    } catch (_) {
      // No token (offline renewal, or the session expired: the auth then
      // signs out, which reconnects anyway): retry later.
      if (!_closed && request == _request) {
        _cancelConnection();
        _scheduleRetry();
      }
      return;
    }
    if (_closed || request != _request) {
      return;
    }
    if (ifTokenChanged && _subscription != null && token == _token) {
      return;
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    _cancelConnection();
    _token = token;
    var connection = ++_connection;
    connectCount++;
    _subscription = connect(token).listen(
      (snapshot) => _onSnapshot(connection, snapshot),
      onError: (Object error, StackTrace stackTrace) =>
          _onError(connection, error, stackTrace),
      onDone: () => _onDone(connection),
      cancelOnError: true,
    );
  }

  void _cancelConnection() {
    var subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel().catchError((Object _) {}));
    }
  }

  void _onSnapshot(int connection, DocumentSnapshot snapshot) {
    if (_closed || connection != _connection) {
      return;
    }
    _retryDelay = initialRetryDelay;
    _tokenRenewed = false;
    var exists = snapshot.exists;
    var updateTime = exists ? snapshot.updateTime : null;
    if (exists == _lastExists && updateTime == _lastUpdateTime) {
      // Duplicate of the last emitted snapshot, skip it.
      return;
    }
    _lastExists = exists;
    _lastUpdateTime = updateTime;
    _controller.add(snapshot);
  }

  void _onError(int connection, Object error, StackTrace stackTrace) {
    if (_closed || connection != _connection) {
      return;
    }
    _subscription = null;
    if (error is GrpcError) {
      if (error.code == StatusCode.permissionDenied) {
        _fail(error, stackTrace);
        return;
      }
      if (error.code == StatusCode.unauthenticated) {
        if (_token != null && !_tokenRenewed) {
          _tokenRenewed = true;
          unawaited(_connect(forceRefresh: true));
        } else {
          _fail(error, stackTrace);
        }
        return;
      }
    }
    _scheduleRetry();
  }

  void _onDone(int connection) {
    if (_closed || connection != _connection) {
      return;
    }
    _subscription = null;
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_closed) {
      return;
    }
    _retryTimer?.cancel();
    var delay = _retryDelay;
    var next = _retryDelay * 2;
    _retryDelay = next > maxRetryDelay ? maxRetryDelay : next;
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      unawaited(_connect());
    });
  }

  void _fail(Object error, StackTrace stackTrace) {
    _controller.addError(error, stackTrace);
    unawaited(close());
  }

  /// Stops listening, closes the stream.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _cancelConnection();
    var authSubscription = _authSubscription;
    _authSubscription = null;
    onClose?.call();
    unawaited(_controller.close());
    await authSubscription?.cancel();
  }
}
