import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_firestore_grpc_rest/firestore_grpc_rest.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/document_reference_rest.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_rest/firebase_rest.dart';

/// Global gRPC REST Firestore service.
FirestoreServiceRest firestoreServiceGrpcRest = FirestoreServiceGrpcRestImpl(
  firestoreServiceRest as FirestoreServiceRestImpl,
);

/// Firestore service gRPC REST implementation.
class FirestoreServiceGrpcRestImpl extends FirestoreServiceRestImpl {
  /// REST delegate.
  final FirestoreServiceRestImpl delegate;

  /// Constructor.
  FirestoreServiceGrpcRestImpl(this.delegate);

  @override
  FirestoreRest firestore(App app) {
    return getInstance(
      app,
      () => FirestoreGrpcRestImpl(this, app as FirebaseAppRest),
    );
  }

  @override
  bool get supportsDocumentSnapshotTime =>
      delegate.supportsDocumentSnapshotTime;

  @override
  bool get supportsFieldValueArray => delegate.supportsFieldValueArray;

  @override
  bool get supportsQuerySelect => delegate.supportsQuerySelect;

  @override
  bool get supportsQuerySnapshotCursor => delegate.supportsQuerySnapshotCursor;

  @override
  bool get supportsTimestamps => delegate.supportsTimestamps;

  @override
  bool get supportsTimestampsInSnapshots =>
      delegate.supportsTimestampsInSnapshots;

  @override
  bool get supportsTrackChanges => delegate.supportsTrackChanges;

  @override
  bool get supportsRecordTrackChanges => true;

  @override
  bool get supportsListCollections => delegate.supportsListCollections;

  @override
  bool get supportsAggregateQueries => delegate.supportsAggregateQueries;

  @override
  bool get supportsVectorValue => delegate.supportsVectorValue;

  @override
  bool get supportsBlobs => delegate.supportsBlobs;
}

/// Firestore gRPC REST implementation.
class FirestoreGrpcRestImpl extends FirestoreRestImpl {
  final _activeListeners = <_GrpcListener>[];

  /// Constructor.
  FirestoreGrpcRestImpl(super.service, super.appImpl);

  @override
  DocumentReference doc(String path) {
    return DocumentReferenceGrpcRestImpl(this, path);
  }

  @override
  void dispose() {
    for (var listener in List<_GrpcListener>.from(_activeListeners)) {
      listener.close();
    }
    _activeListeners.clear();
    super.dispose();
  }
}

/// Document reference gRPC REST implementation.
class DocumentReferenceGrpcRestImpl extends DocumentReferenceRestImpl {
  /// Firestore gRPC REST implementation.
  final FirestoreGrpcRestImpl firestoreGrpcRestImpl;

  /// Constructor.
  DocumentReferenceGrpcRestImpl(this.firestoreGrpcRestImpl, String path)
    : super(firestoreGrpcRestImpl, path);

  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    late StreamController<DocumentSnapshot> controller;
    _GrpcListener? listener;

    controller = StreamController<DocumentSnapshot>(
      onListen: () {
        listener = _GrpcListener(this, controller);
        firestoreGrpcRestImpl._activeListeners.add(listener!);
      },
      onCancel: () {
        listener?.close();
      },
    );

    return controller.stream;
  }
}

class _GrpcListener {
  final DocumentReferenceGrpcRestImpl docRef;
  final StreamController<DocumentSnapshot> controller;

  StreamSubscription? _authSubscription;
  StreamSubscription? _grpcSubscription;
  bool _closed = false;

  User? _lastUser;
  bool _first = true;

  _GrpcListener(this.docRef, this.controller) {
    var app = docRef.firestoreGrpcRestImpl.app;
    if (app.hasAdminCredentials) {
      // Service account app: the client is already authenticated, no user
      // tracking needed (instantiating the auth service would clear the
      // service account client on the app).
      _startListening();
    } else {
      var auth = authServiceRest.auth(app);
      _authSubscription = auth.onCurrentUser.listen((user) {
        if (!_closed) {
          if (_first || user?.uid != _lastUser?.uid) {
            _first = false;
            _lastUser = user;
            _startListening();
          }
        }
      });
    }
  }

  void _startListening() {
    _grpcSubscription?.cancel();
    _grpcSubscription = null;

    if (_closed) return;

    // ignore: cancel_subscriptions
    StreamSubscription? sub;
    var stream = docRef.onGrpcSnapshot();

    sub = stream.listen(
      (snapshot) {
        if (!_closed) {
          controller.add(snapshot);
        }
      },
      onError: (Object error) {
        if (_closed) return;

        var isPermissionError = false;
        if (error is GrpcError) {
          if (error.code == StatusCode.permissionDenied ||
              error.code == StatusCode.unauthenticated) {
            isPermissionError = true;
          }
        }

        if (isPermissionError) {
          controller.addError(error);
          close();
        } else {
          // Retry listening after a short delay on network/connection issues
          Future.delayed(const Duration(seconds: 1), () {
            if (!_closed && _grpcSubscription == sub) {
              _startListening();
            }
          });
        }
      },
      onDone: () {
        if (_closed) return;

        // Reconnect if the stream closes unexpectedly
        Future.delayed(const Duration(seconds: 1), () {
          if (!_closed && _grpcSubscription == sub) {
            _startListening();
          }
        });
      },
      cancelOnError: true,
    );

    _grpcSubscription = sub;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _authSubscription?.cancel();
    _grpcSubscription?.cancel();
    controller.close();
    docRef.firestoreGrpcRestImpl._activeListeners.remove(this);
  }
}
