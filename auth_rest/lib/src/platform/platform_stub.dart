import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/google_auth_rest.dart';

/// Google auth provider rest io
abstract class GoogleAuthProviderRestIo implements GoogleRestAuthProvider {
  /// Factory
  factory GoogleAuthProviderRestIo({
    required GoogleAuthOptions options,
    PromptUserForConsentRest? userPrompt,
    String? credentialPath,
  }) => throw UnsupportedError('io');
}
