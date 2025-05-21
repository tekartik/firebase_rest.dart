import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/google_auth_rest.dart';

abstract class GoogleAuthProviderRestWeb implements GoogleRestAuthProvider {
  factory GoogleAuthProviderRestWeb({required GoogleAuthOptions options}) =>
      throw UnsupportedError('web');
}

abstract class GoogleAuthProviderRestIo implements GoogleRestAuthProvider {
  factory GoogleAuthProviderRestIo({
    required GoogleAuthOptions options,
    PromptUserForConsentRest? userPrompt,
    String? credentialPath,
  }) => throw UnsupportedError('io');
}
