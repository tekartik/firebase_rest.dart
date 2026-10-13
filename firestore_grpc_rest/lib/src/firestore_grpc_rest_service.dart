import 'dart:async';

import 'package:tekartik_firebase_firestore_grpc_rest/src/firestore_grpc_listener.dart';
import 'package:tekartik_firebase_firestore_grpc_rest/src/firestore_grpc_rest.dart';
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
  final _activeListeners = <GrpcDocumentListener>[];

  /// Constructor.
  FirestoreGrpcRestImpl(super.service, super.appImpl);

  @override
  DocumentReference doc(String path) {
    return DocumentReferenceGrpcRestImpl(this, path);
  }

  @override
  void dispose() {
    for (var listener in List<GrpcDocumentListener>.from(_activeListeners)) {
      unawaited(listener.close());
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

  /// The snapshots of the document through the gRPC Listen API, kept open
  /// across connection failures and auth changes (see
  /// [GrpcDocumentListener]): authenticated with the token of the app
  /// client (a signed in user included), reconnected on each sign in or
  /// sign out. A permission denied (the rules) ends the stream with the
  /// error.
  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    var firestore = firestoreGrpcRestImpl;
    late GrpcDocumentListener listener;
    listener = GrpcDocumentListener(
      connect: (token) => grpcListenDocument(this, token: token),
      getToken: ({bool forceRefresh = false}) =>
          grpcListenToken(firestore, forceRefresh: forceRefresh),
      authChanges: firestore.appImpl.onClientChanged,
      onStart: () => firestore._activeListeners.add(listener),
      onClose: () => firestore._activeListeners.remove(listener),
    );
    return listener.stream;
  }
}
