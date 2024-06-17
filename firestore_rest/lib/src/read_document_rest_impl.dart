import 'package:tekartik_firebase_firestore_rest/src/document_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';

import 'firestore/v1_fixed.dart';

class ReadDocument with DocumentContext {
  @override
  final FirestoreDocumentContext firestore;

  // Read data
  Map<String, Object?>? data;

  ReadDocument(this.firestore, Document document) {
    _fromDocument(document);
  }

  void _fromDocument(Document document) {
    data = mapFromFields(firestore, document.fields) ?? <String, Object?>{};
  }
}
