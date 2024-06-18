import 'dart:async';

import 'package:tekartik_firebase_firestore_rest/src/firestore/v1_fixed.dart';
import 'package:tekartik_firebase_rest/src/test/test_setup.dart';
import 'package:tekartik_firebase_rest/src/test/test_setup.dart' as firebase;

export 'package:tekartik_firebase_rest/src/test/test_setup.dart' hide setup;

const _firestoreScopes = [
  FirestoreApi.datastoreScope,
  firebaseGoogleApisUserEmailScope,
  // "https://www.googleapis.com/auth/userinfo.email"
];

Future<FirebaseRestTestContext?> firestoreRestSetup({bool? useEnv}) async {
  return await firebase.setup(scopes: _firestoreScopes, useEnv: useEnv);
}
