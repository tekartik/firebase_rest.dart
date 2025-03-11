library;

export 'package:tekartik_firebase_auth/auth.dart';
export 'package:tekartik_firebase_auth_rest/src/auth_rest.dart'
    show
        firebaseAuthServiceRest,
        authServiceRest,
        debugFirebaseAuthRest,
        FirebaseAuthRest,
        AuthRest, // compat
        AuthRestExt,
        // ignore: deprecated_member_use_from_same_package
        AuthRestProvider,
        UserRecordRest,
        PromptUserForConsentRest,
        AuthProviderRest;
export 'package:tekartik_firebase_auth_rest/src/google_auth_rest.dart'
    show GoogleAuthOptions;

/// Build an authorization header.
String getAuthorizationHeader(String token) => 'Bearer $token';

/// Parse authorization header
String parseAuthorizationHeaderToken(String authorization) {
  var parts = authorization.split(' ');
  return parts[1];
}
