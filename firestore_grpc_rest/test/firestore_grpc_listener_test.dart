import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_grpc_rest/src/firestore_grpc_listener.dart';
import 'package:test/test.dart';

/// Only exists and updateTime matter to the listener.
class _Snapshot implements DocumentSnapshot {
  @override
  final bool exists;
  @override
  final Timestamp? updateTime;

  _Snapshot(int? seconds)
    : exists = seconds != null,
      updateTime = seconds == null ? null : Timestamp(seconds, 0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One connection opened by the listener.
class _Connection {
  final String? token;
  final controller = StreamController<DocumentSnapshot>();
  var cancelled = false;

  _Connection(this.token) {
    controller.onCancel = () {
      cancelled = true;
    };
  }
}

class _Context {
  final connections = <_Connection>[];
  final tokenRequests = <bool>[];
  final authChanges = StreamController<Object?>.broadcast();
  String? token = 't1';
  StateError? tokenError;
  late final GrpcDocumentListener listener;
  final snapshots = <DocumentSnapshot>[];
  final errors = <Object>[];
  var done = false;
  late final StreamSubscription<DocumentSnapshot> subscription;

  _Context({
    Duration initialRetryDelay = const Duration(milliseconds: 20),
    Duration maxRetryDelay = const Duration(milliseconds: 80),
  }) {
    listener = GrpcDocumentListener(
      connect: (token) {
        var connection = _Connection(token);
        connections.add(connection);
        return connection.controller.stream;
      },
      getToken: ({bool forceRefresh = false}) async {
        tokenRequests.add(forceRefresh);
        var error = tokenError;
        if (error != null) {
          throw error;
        }
        if (forceRefresh && token != null) {
          token = '${token}r';
        }
        return token;
      },
      authChanges: authChanges.stream,
      initialRetryDelay: initialRetryDelay,
      maxRetryDelay: maxRetryDelay,
    );
  }

  _Connection get last => connections.last;

  void listen() {
    subscription = listener.stream.listen(
      snapshots.add,
      onError: errors.add,
      onDone: () => done = true,
    );
  }

  /// Waits for [count] connections.
  Future<void> waitConnections(int count) async {
    var sw = Stopwatch()..start();
    while (connections.length < count) {
      if (sw.elapsed > const Duration(seconds: 5)) {
        fail('${connections.length} connections, $count expected');
      }
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  Future<void> close() async {
    await subscription.cancel();
    await authChanges.close();
  }
}

Future<void> _pump([int ms = 10]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  group('GrpcDocumentListener', () {
    test('emits each state once', () async {
      var context = _Context()..listen();
      await context.waitConnections(1);
      expect(context.last.token, 't1');
      context.last.controller
        ..add(_Snapshot(null))
        ..add(_Snapshot(null))
        ..add(_Snapshot(1))
        ..add(_Snapshot(1))
        ..add(_Snapshot(2));
      await _pump();
      expect(context.snapshots.map((s) => s.updateTime?.seconds), [null, 1, 2]);
      await context.close();
    });

    test('reconnects with a growing delay, reset by a snapshot', () async {
      var context = _Context()..listen();
      await context.waitConnections(1);
      var sw = Stopwatch()..start();
      context.last.controller.addError(const GrpcError.unavailable('lost'));
      await context.waitConnections(2);
      var first = sw.elapsed;
      sw.reset();
      context.last.controller.addError(const GrpcError.unavailable('lost'));
      await context.waitConnections(3);
      var second = sw.elapsed;
      expect(first, greaterThanOrEqualTo(const Duration(milliseconds: 20)));
      expect(second, greaterThanOrEqualTo(const Duration(milliseconds: 40)));
      expect(context.connections.take(2).every((c) => c.cancelled), isTrue);

      // A snapshot resets the delay.
      context.last.controller.add(_Snapshot(1));
      await _pump();
      sw.reset();
      // The server closing the connection is retried too.
      await context.last.controller.close();
      await context.waitConnections(4);
      expect(sw.elapsed, lessThan(const Duration(milliseconds: 40)));
      expect(context.errors, isEmpty);
      expect(context.done, isFalse);
      // The same state after the reconnection is not emitted again.
      context.last.controller.add(_Snapshot(1));
      await _pump();
      expect(context.snapshots, hasLength(1));
      await context.close();
    });

    test('the delay stops growing at its max', () async {
      var context = _Context(
        initialRetryDelay: const Duration(milliseconds: 10),
        maxRetryDelay: const Duration(milliseconds: 20),
      )..listen();
      for (var i = 1; i <= 4; i++) {
        await context.waitConnections(i);
        context.last.controller.addError(const GrpcError.unavailable('lost'));
      }
      var sw = Stopwatch()..start();
      await context.waitConnections(5);
      expect(sw.elapsed, lessThan(const Duration(milliseconds: 200)));
      await context.close();
    });

    test('permission denied ends the stream', () async {
      var context = _Context()..listen();
      await context.waitConnections(1);
      context.last.controller.addError(
        const GrpcError.permissionDenied('rules'),
      );
      await _pump(60);
      expect(context.errors.single, isA<GrpcError>());
      expect(context.done, isTrue);
      expect(context.connections, hasLength(1));
      expect(context.listener.isClosed, isTrue);
      await context.close();
    });

    test('unauthenticated renews the token once', () async {
      var context = _Context()..listen();
      await context.waitConnections(1);
      context.last.controller.addError(
        const GrpcError.unauthenticated('expired'),
      );
      await context.waitConnections(2);
      expect(context.tokenRequests, [false, true]);
      expect(context.last.token, 't1r');

      // Working again: a later expiration renews again.
      context.last.controller.add(_Snapshot(1));
      await _pump();
      context.last.controller.addError(
        const GrpcError.unauthenticated('expired'),
      );
      await context.waitConnections(3);
      expect(context.last.token, 't1rr');

      // Refused right after a renewal: the error ends the stream.
      context.last.controller.addError(
        const GrpcError.unauthenticated('refused'),
      );
      await _pump(60);
      expect(context.errors.single, isA<GrpcError>());
      expect(context.done, isTrue);
      expect(context.connections, hasLength(3));
      await context.close();
    });

    test('unauthenticated without token ends the stream', () async {
      var context = _Context()..token = null;
      context.listen();
      await context.waitConnections(1);
      context.last.controller.addError(
        const GrpcError.unauthenticated('no token'),
      );
      await _pump(60);
      expect(context.errors, hasLength(1));
      expect(context.done, isTrue);
      await context.close();
    });

    test('auth changes reconnect with the new token', () async {
      var context = _Context()..listen();
      await context.waitConnections(1);
      context.last.controller.add(_Snapshot(1));
      await _pump();

      // Same token: the connection stays.
      context.authChanges.add(Object());
      await _pump();
      expect(context.connections, hasLength(1));

      // Another user.
      context.token = 'u2';
      context.authChanges.add(Object());
      await context.waitConnections(2);
      expect(context.last.token, 'u2');
      expect(context.connections.first.cancelled, isTrue);

      // Signed out: unauthenticated.
      context.token = null;
      context.authChanges.add(null);
      await context.waitConnections(3);
      expect(context.last.token, isNull);
      await context.close();
    });

    test('an auth change during a retry delay reconnects now', () async {
      var context = _Context(
        initialRetryDelay: const Duration(seconds: 10),
        maxRetryDelay: const Duration(seconds: 10),
      )..listen();
      await context.waitConnections(1);
      context.last.controller.addError(const GrpcError.unavailable('lost'));
      await _pump();
      context.authChanges.add(Object());
      await context.waitConnections(2);
      await context.close();
    });

    test('a token error is retried', () async {
      var context = _Context()..tokenError = StateError('offline');
      context.listen();
      await _pump(30);
      expect(context.connections, isEmpty);
      context.tokenError = null;
      await context.waitConnections(1);
      expect(context.tokenRequests.length, greaterThanOrEqualTo(2));
      await context.close();
    });

    test('cancel closes the connection and stops retrying', () async {
      var context = _Context()..listen();
      await context.waitConnections(1);
      context.last.controller.addError(const GrpcError.unavailable('lost'));
      await _pump(2);
      await context.subscription.cancel();
      expect(context.listener.isClosed, isTrue);
      await _pump(100);
      expect(context.connections, hasLength(1));

      var context2 = _Context()..listen();
      await context2.waitConnections(1);
      await context2.subscription.cancel();
      await _pump();
      expect(context2.last.cancelled, isTrue);
      context2.authChanges.add(Object());
      await _pump();
      expect(context2.connections, hasLength(1));
      await context.authChanges.close();
      await context2.authChanges.close();
    });
  });
}
