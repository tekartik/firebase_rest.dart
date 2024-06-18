import 'dart:async';

import 'package:tekartik_firebase_rest/src/test/test_setup.dart';
import 'package:tekartik_firebase_rest/src/test/test_setup.dart' as firebase;

Future<FirebaseRestTestContext?> authRestSetup({bool? useEnv}) async {
  return await firebase.setup(scopes: firebaseBaseScopes, useEnv: useEnv);
}
