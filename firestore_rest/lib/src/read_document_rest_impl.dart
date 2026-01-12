import 'package:tekartik_firebase_firestore_rest/src/document_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';

import 'firestore/v1.dart';

/// Read document.
class ReadDocument with DocumentContext {
  /// Firestore context.
  @override
  final FirestoreDocumentContext firestore;

  // Read data
  /// Read data.
  Map<String, Object?>? data;

  /// Constructor.
  ReadDocument(this.firestore, Document document) {
    _fromDocument(document);
  }

  void _fromDocument(Document document) {
    data = mapFromFields(firestore, document.fields) ?? <String, Object?>{};
  }
}
