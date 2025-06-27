import 'dart:io';

import 'package:fs_shim/utils/io/read_write.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

import 'google_auth_rest.dart';

class GoogleAuthProviderRestIoImpl
    with GoogleRestAuthProviderMixin
    implements GoogleAuthProviderRestIo {
  AuthClient? _authClient;

  @override
  AuthClient get currentAuthClient => _authClient!;

  @override
  AuthClient get client => _authClient!;

  @override
  String get apiKey => googleAuthOptions.apiKey!;

  /// Optional io path for saving credentials.
  final String? credentialPath;
  late auth_io.PromptUserForConsent userPrompt;

  GoogleAuthProviderRestIoImpl(
    final GoogleAuthOptions googleAuthOptions, {
    List<String>? scopes,
    auth_io.PromptUserForConsent? userPrompt,
    this.credentialPath,
  }) {
    this.googleAuthOptions = googleAuthOptions;
    this.userPrompt =
        userPrompt ??
        (prompt) {
          print('userPrompt: $prompt');
        };
    // devPrint('GoogleAuthProviderRestImpl($googleAuthOptions, $scopes');
    this.scopes =
        scopes ??
        [
          ...firebaseBaseScopes,
          'https://www.googleapis.com/auth/devstorage.read_write',
          'https://www.googleapis.com/auth/datastore',
          // OAuth scope
          // 'https://www.googleapis.com/auth/firebase'
          //'https://www.googleapis.com/auth/contacts.readonly',
          'https://www.googleapis.com/auth/contacts.readonly',
        ];
  }

  @override
  Stream<FirebaseUserRest?> get onCurrentUser {
    late StreamController<FirebaseUserRest?> ctlr;
    if (currentUserController == null) {
      ctlr = currentUserController ??= StreamController.broadcast(
        onListen: () async {
          // Get first client, next will sent through currentUserController
          try {
            var client = _authClient;
            if (client == null) {
              if (credentialPath != null) {
                auth_io.AccessCredentials? accessCredentials;
                var file = File(credentialPath!);
                if (!file.existsSync()) {
                  stderr.writeln('Credential file not found, logging in');
                } else {
                  try {
                    final yaml = jsonDecode(file.readAsStringSync()) as Map;
                    //devPrint(yaml);
                    accessCredentials = auth_io.AccessCredentials.fromJson(
                      yaml.cast<String, Object?>(),
                    );
                  } catch (e, st) {
                    stderr.writeln('error $e loading credentials, logging in');
                    stderr.writeln(st);
                    // exit(1);
                  }
                }
                if (accessCredentials != null) {
                  await _initWithAccessCredentials(accessCredentials);
                  return;
                }
              }
              setCurrentUser(null);
            } else {
              // Handle on init.
              setCurrentUser(currentUser);
            }
          } catch (_) {}
          setCurrentUser(null);
        },
      );
      return ctlr.stream;
    } else {
      return _onCurrentUser;
    }
  }

  Stream<FirebaseUserRest?> get _onCurrentUser async* {
    yield currentUser;
    yield* currentUserController!.stream;
  }

  //Future<String> getIdToken() async {}
  Future<UserRest?> getUserMe() async {
    return null;
    /*
    final SecureTokenApi secureTokenApi = SecureTokenApi(
      client: auth._apiKeyClient,
      accessToken: accessToken,
      accessTokenExpirationDate: accessTokenExpirationDate,
      refreshToken: refreshToken,
    );

    final FirebaseUser user =
        FirebaseUser._(secureTokenApi: secureTokenApi, auth: auth);
    final String newAccessToken = await user._getToken();

    final IdentitytoolkitRelyingpartyGetAccountInfoRequest request =
        IdentitytoolkitRelyingpartyGetAccountInfoRequest()
          ..idToken = newAccessToken;

    final GetAccountInfoResponse response =
        await auth._firebaseAuthApi.getAccountInfo(request);

    return user
      .._isAnonymous = anonymous
      .._updateWithUserDataResponse(response);
     */
  }

  void _closeClient() {
    _authClient?.close();
    _authClient = null;
  }

  Future<UserRest> _initWithAccessCredentials(
    auth_io.AccessCredentials accessCredentials,
  ) async {
    var clientId = googleAuthOptions.clientId!;
    var httpClient = Client();
    var authClientId = ClientId(clientId, googleAuthOptions.clientSecret);
    // devPrint('accessCredentials: ${accessCredentials.toJson()}');
    var authClient = auth_io.autoRefreshingClient(
      authClientId,
      accessCredentials,
      httpClient,
    );
    /*
      var accessCredentials = await clientViaUserConsent(
          clientId, scopes);
      var authClient = auth_browser.authenticatedClient(
          Client(), accessCredentials,
          closeUnderlyingClient: true);*/

    /*
      // devPrint('ID token: ${client.credentials.idToken}');
      authClient.credentialUpdates.listen((event) {
        // devPrint('update: token ${event.idToken}');
      });*/
    _authClient = authClient;
    // devPrint(authClient);
    // devPrint(client.credentials.accessToken);
    /*
      var appOptions = AppOptionsRest(client: authClient)
        ..projectId = googleAuthOptions.projectId;

       */
    /*
      var app = await firebaseRest.initializeAppAsync(options: appOptions);
      auth = authServiceRest.auth(app);
      */
    var oauth2Api = Oauth2Api(authClient);

    // Get me special!
    final person = await oauth2Api.userinfo.get();

    // On success, write credentials
    if (credentialPath != null) {
      var file = File(credentialPath!);
      await writeString(file, jsonEncode(accessCredentials.toJson()));
    }
    // devPrint(jsonPretty(person.toJson()));
    // devPrint(auth.currentUser);
    var user =
        FirebaseUserRest(
            client: authClient,
            emailVerified: person.verifiedEmail ?? false,
            uid: person.id!,
            provider: this,
          )
          ..email = person.email
          ..displayName = person.name
          ..accessCredentials = accessCredentials;

    () async {
      // devPrint('adding user $user ($currentUserController)');
      setCurrentUser(user);
    }().unawait();
    return user;
  }

  @override
  Future<AuthSignInResult> signIn() async {
    // var clientId = googleAuthOptions.clientId!;
    // devPrint('signing in...rest_web');
    try {
      _closeClient();
      var clientId = googleAuthOptions.clientId!;
      var authClientId = ClientId(clientId, googleAuthOptions.clientSecret);
      /*
      var responseCode = await auth_browser.requestAuthorizationCode(
          clientId: clientId, scopes: scopes);

      devPrint(responseCode.toString());
      var accessCredentials = await obtainAccessCredentialsViaCodeExchange(
          Client(), authClientId, responseCode.code);
      var authClient = auth_browser.autoRefreshingClient(
          authClientId, accessCredentials, Client());

                 */

      var httpClient = Client();

      var accessCredentials = await auth_io
          .obtainAccessCredentialsViaUserConsent(
            authClientId,
            scopes,
            httpClient,
            userPrompt,
          );

      var user = await _initWithAccessCredentials(accessCredentials);
      var result = AuthSignInResultRest(client: _authClient!, provider: this)
        ..hasInfo = true
        ..credential = UserCredentialRestImpl(
          AuthCredentialRestImpl(providerId: providerId),
          user,
        );
      return result;
    } catch (e) {
      // devPrint('error $e');
      rethrow;
    }
    // devPrint('signing done');
  }

  @override
  Future<void> signOut() async {
    setCurrentUser(null);
    _closeClient();
  }
}

/// Rest IO provider (manual login)
abstract class GoogleAuthProviderRestIo implements GoogleRestAuthProvider {
  factory GoogleAuthProviderRestIo({
    required GoogleAuthOptions options,
    PromptUserForConsentRest? userPrompt,
    String? credentialPath,
  }) => GoogleAuthProviderRestIoImpl(
    options,
    userPrompt: userPrompt,
    credentialPath: credentialPath,
  );
}
