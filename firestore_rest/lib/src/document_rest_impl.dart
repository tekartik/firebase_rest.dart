import 'package:tekartik_firebase_firestore_rest/src/firestore/v1.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';

import 'firestore_rest_impl.dart' as rest;

/// Document context.
abstract class FirestoreDocumentContext {
  /// Firestore implementation.
  FirestoreRestImpl get impl;

  // Full name
  /// Get document name from path.
  String getDocumentName(String path);

  // Path below documents
  /// Get document path from name.
  String? getDocumentPath(String? name);
}

/// Document context mixin.
mixin DocumentContext {
  /// Firestore document context.
  FirestoreDocumentContext get firestore;

  /// Convert to rest value.
  Value toRestValue(dynamic value) {
    return rest.toRestValue(firestore.impl, value);
  }
}
