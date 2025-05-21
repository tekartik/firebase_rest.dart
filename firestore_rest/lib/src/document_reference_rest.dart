import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/reference_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';
import 'package:tekartik_firebase_firestore_rest/src/collection_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1.dart' as api;
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';

class DocumentReferenceRestImpl
    with
        DocumentReferenceDefaultMixin,
        DocumentReferenceMixin,
        PathReferenceImplMixin,
        PathReferenceMixin,
        PathReferenceRestMixin
    implements DocumentReference {
  DocumentReferenceRestImpl(FirestoreRestImpl firestoreRest, String path) {
    init(firestoreRest, path);
    checkDocumentReferencePath(this.path);
  }

  @override
  Future delete() => firestoreRestImpl.deleteDocument(path);

  @override
  Future<DocumentSnapshot> get() => firestoreRestImpl.getDocument(path);

  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) =>
      throw UnsupportedError('onSnapshot not supported');

  @override
  Future set(Map<String, Object?> data, [SetOptions? options]) =>
      firestoreRestImpl.writeDocument(path, data, merge: options?.merge);

  @override
  Future update(Map<String, Object?> data) =>
      firestoreRestImpl.updateDocument(path, data);

  @override
  Future<List<CollectionReference>> listCollections() async {
    return firestoreRestImpl.listDocumentCollections(path);
  }
}

class DocumentSnapshotRestImpl
    with DocumentSnapshotMixin
    implements DocumentSnapshot {
  final FirestoreRestImpl firestoreRestImpl;
  final api.Document? impl;

  DocumentSnapshotRestImpl(this.firestoreRestImpl, this.impl);

  @override
  Timestamp? get createTime => Timestamp.tryParse(impl!.createTime!);

  /// Never null if it exists.
  @override
  Map<String, Object?> get data =>
      exists
          ? (mapFromFields(firestoreRestImpl, impl!.fields) ??
              <String, Object?>{})
          : throw StateError('no data');

  /// Sometimes in get we have a Document will all fields null.
  @override
  bool get exists => impl?.createTime != null;

  @override
  DocumentReference get ref => DocumentReferenceRestImpl(
    firestoreRestImpl,
    firestoreRestImpl.getDocumentPath(impl!.name),
  );

  @override
  Timestamp? get updateTime => Timestamp.tryParse(impl!.updateTime!);
}
