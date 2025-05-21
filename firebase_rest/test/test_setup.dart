import 'dart:async';

import 'package:tekartik_firebase_rest/src/test/test_setup.dart';
import 'package:tekartik_firebase_rest/src/test/test_setup.dart' as firebase;

export 'package:tekartik_firebase_rest/src/test/test_setup.dart'
    show
        // ignore: deprecated_member_use_from_same_package
        getContextFromAccessToken,
        getAppOptionsFromAccessToken;

/// Setup helper
Future<FirebaseRestTestContext?> firebaseRestSetup({
  String? serviceAccountJsonPath,
  Map? serviceAccountMap,
  bool? useEnv,
}) async {
  return await firebase.setup(
    scopes: firebaseBaseScopes,
    serviceAccountJsonPath: serviceAccountJsonPath,
    serviceAccountMap: serviceAccountMap,
    useEnv: useEnv,
  );
}
