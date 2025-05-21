/// Scopes for Firebase Auth.
const firebaseGoogleApisUserEmailScope =
    'https://www.googleapis.com/auth/userinfo.email';

/// Scopes for Cloud platform.
const firebaseGoogleApisCloudPlatformScope =
    'https://www.googleapis.com/auth/cloud-platform';

/// Base scopes for Firebase.
const firebaseBaseScopes = [
  firebaseGoogleApisCloudPlatformScope,
  firebaseGoogleApisUserEmailScope,
];
