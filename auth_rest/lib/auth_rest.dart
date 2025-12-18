library;

export 'package:tekartik_firebase_auth/auth.dart';
export 'package:tekartik_firebase_auth_rest/src/auth_rest.dart'
    show
        debugFirebaseAuthRest,
        FirebaseAuthRest,
        AuthRest, // compat
        FirebaseAuthRestExt,
        UserRecordRest,
        PromptUserForConsentRest;
export 'package:tekartik_firebase_auth_rest/src/auth_rest_built_in_provider.dart'
    show BuiltInAuthProviderRest;
export 'package:tekartik_firebase_auth_rest/src/auth_rest_mock_provider.dart'
    show MockBuiltInAuthProviderRest;
export 'package:tekartik_firebase_auth_rest/src/auth_rest_provider.dart'
    show AuthProviderRest;
export 'package:tekartik_firebase_auth_rest/src/auth_service_rest.dart'
    show firebaseAuthServiceRest, FirebaseAuthServiceRest, authServiceRest;
export 'package:tekartik_firebase_auth_rest/src/google_auth_rest.dart'
    show GoogleAuthOptions;

export 'src/auth_rest_persistence.dart'
    show
        FirebaseRestAuthPersistence,
        FirebaseRestAuthPersistenceAccessCredentials,
        FirebaseRestAuthPersistenceFile,
        FirebaseRestAuthPersistenceWeb,
        FirebaseRestAuthPersistenceMemory;

/// Build an authorization header.
String getAuthorizationHeader(String token) => 'Bearer $token';

/// Parse authorization header
String parseAuthorizationHeaderToken(String authorization) {
  var parts = authorization.split(' ');
  return parts[1];
}
