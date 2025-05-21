import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/query_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/src/common/reference_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_rest/src/collection_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/document_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1.dart'
    show RunQueryResponse;
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';

import 'aggregate_query_rest.dart';

class QueryRestImpl
    with
        QueryDefaultMixin,
        QueryMixin,
        PathReferenceMixin,
        PathReferenceImplMixin,
        PathReferenceRestMixin,
        FirestoreQueryExecutorMixin
    implements Query {
  QueryRestImpl(FirestoreRestImpl firestoreRest, String path) {
    init(firestoreRest, path);
  }

  @override
  Stream<QuerySnapshot> onSnapshot({bool includeMetadataChanges = false}) =>
      throw UnsupportedError('onSnapshot not supported');

  @override
  QueryMixin clone() {
    return QueryRestImpl(firestoreRestImpl, path)
      ..queryInfo = queryInfo.clone();
  }

  @override
  Future<QuerySnapshot> get() => firestoreRestImpl.runQuery(this);

  @override
  AggregateQuery aggregate(List<AggregateField> fields) {
    return AggregateQueryRest(this, fields);
  }
}

class QuerySnapshotRestImpl implements QuerySnapshot {
  final FirestoreRestImpl firestoreRest;
  final RunQueryResponse response;

  QuerySnapshotRestImpl(this.firestoreRest, this.response);

  List<DocumentSnapshot>? _docs;

  @override
  List<DocumentSnapshot> get docs =>
      _docs ??= () {
        return response
            .map(
              (document) =>
                  DocumentSnapshotRestImpl(firestoreRest, document.document),
            )
            .where((snapshot) => isDocumentSnapshot(snapshot))
            .toList(growable: false);
      }();

  @override
  List<DocumentChange> get documentChanges =>
      throw UnsupportedError('no document changes on rest');
}

/// For empty result we get this: [{readTime: 2019-11-02T15:24:14.458076Z}]
bool isDocumentSnapshot(DocumentSnapshotRestImpl snapshot) {
  return snapshot.exists;
}
