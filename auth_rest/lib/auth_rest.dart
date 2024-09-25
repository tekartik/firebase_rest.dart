library;

import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart' as auth_rest;

export 'package:tekartik_firebase_auth/auth.dart';
export 'package:tekartik_firebase_auth_rest/src/auth_rest.dart'
    show
        AuthRest,
        AuthRestExt,
        // ignore: deprecated_member_use_from_same_package
        AuthRestProvider,
        UserRecordRest,
        PromptUserForConsentRest,
        AuthProviderRest;
export 'package:tekartik_firebase_auth_rest/src/google_auth_rest.dart'
    show GoogleAuthOptions;

FirebaseAuthService get authServiceRest => auth_rest.authService;

@Deprecated('Use authServiceRest')
FirebaseAuthService get authService => authServiceRest;

/// Build an authorization header.
String getAuthorizationHeader(String token) => 'Bearer $token';

/// Parse authorization header
String parseAuthorizationHeaderToken(String authorization) {
  var parts = authorization.split(' ');
  return parts[1];
}
