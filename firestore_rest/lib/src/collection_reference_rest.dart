import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/query_rest.dart';

import 'import_firestore.dart';

mixin PathReferenceRestMixin implements FirestorePathReference {
  FirestoreRestImpl get firestoreRestImpl => firestore as FirestoreRestImpl;
}

class CollectionReferenceRestImpl extends QueryRestImpl
    with CollectionReferenceMixin
    implements CollectionReference {
  CollectionReferenceRestImpl(FirestoreRestImpl firestoreRest, String path)
      : super(firestoreRest, path) {
    checkCollectionReferencePath(path);
    queryInfo = QueryInfo();
  }

  @override
  Future<DocumentReference> add(Map<String, Object?> data) =>
      firestoreRestImpl.createDocument(path, data);
}
