import 'package:tekartik_firebase_firestore_rest/src/firestore/v1.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';

import 'firestore_rest_impl.dart' as rest;

abstract class FirestoreDocumentContext {
  FirestoreRestImpl get impl;

  // Full name
  String getDocumentName(String path);

  // Path below documents
  String? getDocumentPath(String? name);
}

mixin DocumentContext {
  FirestoreDocumentContext get firestore;

  Value toRestValue(dynamic value) {
    return rest.toRestValue(firestore.impl, value);
  }
}
