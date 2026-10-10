import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart';
import 'package:tekartik_firebase_auth/auth.dart';

import 'auth_rest.dart';
import 'auth_rest_built_in_provider.dart';
import 'auth_rest_provider.dart';
import 'google_auth_rest.dart';

/// The scopes giving a Google id token, all a firebase sign in needs.
const googleIdpSignInScopes = ['openid', 'email', 'profile'];

/// Google sign in of a firebase user from io (desktop, console).
///
/// The Google consent opens in a browser ([userPrompt] gets its url) and
/// comes back to a loopback server; the Google id token it gives is then
/// exchanged for a firebase user ([BuiltInAuthProviderRest.signInWithIdp]):
/// the same user as a Google sign in of flutterfire, same uid, security
/// rules applied, its renewable session persisted like an email/password
/// one. The signed in user belongs to the built-in provider, which must be
/// in the providers too.
///
/// Unlike [GoogleAuthProviderRestIo], which signs a Google account in (the
/// Google id as uid, firestore reached with OAuth scopes as that account,
/// the rules bypassed): a developer tool, this one is for the users of an
/// app.
///
/// [GoogleAuthOptions.clientId] and [GoogleAuthOptions.clientSecret] are
/// those of an OAuth client of the "Desktop app" type (a web client refuses
/// the random loopback port), created in the Google Cloud project of the
/// firebase project so that firebase accepts its id tokens. The secret of
/// such a client is not one, it ships with the app.
class GoogleIdpAuthProviderRestIoImpl extends AuthProviderRestBase
    implements GoogleIdpAuthProviderRestIo {
  /// The OAuth client.
  final GoogleAuthOptions googleAuthOptions;

  final _scopes = <String>[...googleIdpSignInScopes];

  /// Directs the user to the consent url, printed by default.
  late PromptUserForConsentRest _userPrompt;

  /// Google sign in of a firebase user from io.
  GoogleIdpAuthProviderRestIoImpl(
    this.googleAuthOptions, {
    PromptUserForConsentRest? userPrompt,
  }) {
    _userPrompt =
        userPrompt ??
        (uri) {
          // ignore: avoid_print
          print('Sign in with Google: $uri');
        };
  }

  @override
  set userPrompt(PromptUserForConsentRest userPrompt) {
    _userPrompt = userPrompt;
  }

  @override
  String get providerId => googleIdpProviderId;

  @override
  void addScope(String scope) {
    _scopes.add(scope);
  }

  BuiltInAuthProviderRest get _builtInProvider => authRest.impl.builtInProvider;

  @override
  Future<AuthSignInResult> signIn() async {
    var client = Client();
    try {
      var credentials = await auth_io.obtainAccessCredentialsViaUserConsent(
        auth_io.ClientId(
          googleAuthOptions.clientId!,
          googleAuthOptions.clientSecret,
        ),
        _scopes,
        client,
        (uri) => _userPrompt(uri),
      );
      var idToken = credentials.idToken;
      if (idToken == null) {
        throw StateError('No Google id token, openid scope missing?');
      }
      var userCredential = await _builtInProvider.signInWithIdp(
        idToken: idToken,
      );
      return _AuthSignInResultIdp(userCredential);
    } finally {
      client.close();
    }
  }

  /// The signed in user lives in the built-in provider.
  @override
  Future<void> signOut() => _builtInProvider.signOut();

  @override
  String toString() =>
      'GoogleIdpAuthProviderRestIo(${googleAuthOptions.clientId})';
}

class _AuthSignInResultIdp implements AuthSignInResult {
  @override
  final UserCredential credential;

  _AuthSignInResultIdp(this.credential);

  @override
  bool get hasInfo => true;

  @override
  String toString() => 'Result($credential)';
}

/// Google sign in of a firebase user from io (desktop, console), see
/// [GoogleIdpAuthProviderRestIoImpl].
abstract class GoogleIdpAuthProviderRestIo implements GoogleRestAuthProvider {
  /// [options] holds the id and secret of a "Desktop app" OAuth client of the
  /// firebase project.
  factory GoogleIdpAuthProviderRestIo({
    required GoogleAuthOptions options,
    PromptUserForConsentRest? userPrompt,
  }) => GoogleIdpAuthProviderRestIoImpl(options, userPrompt: userPrompt);
}
