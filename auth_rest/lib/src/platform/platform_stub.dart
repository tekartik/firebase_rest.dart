import 'package:tekartik_firebase_auth_rest/auth_rest.dart';

/// Google auth provider rest io
abstract class GoogleAuthProviderRestIo implements GoogleRestAuthProvider {
  /// Factory
  factory GoogleAuthProviderRestIo({
    required GoogleAuthOptions options,
    PromptUserForConsentRest? userPrompt,
    String? credentialPath,
    KvStore? credentialsPersistence,
    String? credentialsKey,
  }) => throw UnsupportedError('io');
}

/// Google sign in of a firebase user from io (desktop, console), io only.
abstract class GoogleIdpAuthProviderRestIo implements GoogleRestAuthProvider {
  /// Factory
  factory GoogleIdpAuthProviderRestIo({
    required GoogleAuthOptions options,
    PromptUserForConsentRest? userPrompt,
  }) => throw UnsupportedError('io');
}
