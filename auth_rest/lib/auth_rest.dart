/// Firebase Auth over the Identity Toolkit REST API, on an app of
/// `tekartik_firebase_rest`: email/password, anonymous and identity provider
/// sign in, id token renewal, persisted sessions and, with a service account,
/// the admin lookups.
///
/// Start with [firebaseAuthServiceRest] (or [FirebaseAuthServiceRest] with a
/// persistence) and `auth(app)`. `auth_rest_io.dart` adds the Google consent
/// providers (VM only).
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
    show BuiltInAuthProviderRest, AuthCredentialIdpRest, googleIdpProviderId;
export 'package:tekartik_firebase_auth_rest/src/auth_rest_mock_provider.dart'
    show MockBuiltInAuthProviderRest;
export 'package:tekartik_firebase_auth_rest/src/auth_rest_provider.dart'
    show AuthProviderRest;
export 'package:tekartik_firebase_auth_rest/src/auth_rest_token.dart'
    show
        RestAuthTokens,
        RestAuthTokenRefresher,
        RestAuthTokenRefreshException,
        idTokenExpiration;
export 'package:tekartik_firebase_auth_rest/src/auth_service_rest.dart'
    show
        firebaseAuthServiceRest,
        firebaseAuthServiceRestAdmin,
        FirebaseAuthServiceRest,
        authServiceRest;
export 'package:tekartik_firebase_auth_rest/src/google_auth_rest.dart'
    show GoogleAuthOptions, GoogleRestAuthProvider;
export 'package:tekartik_firebase_persistence/firebase_persistence.dart'
    show
        KvStore,
        KvStoreExt,
        KvStoreRead,
        KvStoreWrite,
        TekartikFirebasePersistenceMemory,
        TekartikFirebasePersistenceWebLocalStorage,
        TekartikFirebasePersistenceFile,
        TekartikFirebasePersistenceSdb;

export 'src/auth_rest_persistence.dart'
    show
        FirebaseRestAuthPersistence,
        FirebaseRestAuthPersistenceAccessCredentials,
        FirebaseRestAuthPersistenceOnPersistence,
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
