import 'package:googleapis/oauth2/v2.dart';
import 'package:googleapis_auth/auth_browser.dart' as auth_browser;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:yaml/yaml.dart';

import 'google_auth_rest.dart';

class GoogleAuthProviderRestImpl
    with GoogleRestAuthProviderMixin
    implements GoogleAuthProviderRestWeb {
  AuthClient? _authClient;

  @override
  AuthClient get currentAuthClient => _authClient!;

  @override
  AuthClient get client => _authClient!;

  @override
  String get apiKey => googleAuthOptions.apiKey!;

  GoogleAuthProviderRestImpl(GoogleAuthOptions googleAuthOptions,
      {List<String>? scopes}) {
    this.googleAuthOptions = googleAuthOptions;
    // devPrint('GoogleAuthProviderRestImpl($googleAuthOptions, $scopes');
    this.scopes = scopes ??
        [
          ...firebaseBaseScopes,
          'https://www.googleapis.com/auth/devstorage.read_write',
          'https://www.googleapis.com/auth/datastore',
          // OAuth scope
          // 'https://www.googleapis.com/auth/firebase'
          //'https://www.googleapis.com/auth/contacts.readonly',
          'https://www.googleapis.com/auth/contacts.readonly'
        ];
  }

  @override
  Stream<FirebaseUserRest?> get onCurrentUser {
    late StreamController<FirebaseUserRest?> ctlr;
    ctlr = currentUserController ??=
        StreamController.broadcast(onListen: () async {
      // Get first client, next will sent through currentUserController
      try {
        var client = _authClient;
        if (client != null) {
          var credentials = client.credentials;
          setCurrentUser(toUserRest(credentials));
        } else {
          setCurrentUser(null);
        }
      } catch (_) {
        setCurrentUser(null);
      }
    });

    return ctlr.stream;
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

  UserRest toUserRest(AccessCredentials credentials) {
    return UserRest(emailVerified: true, uid: '', provider: this, client: null)
      ..accessCredentials = credentials;
  }

  void _closeClient() {
    _authClient?.close();
    _authClient = null;
  }

  @override
  Future<AuthSignInResult> signIn() async {
    // var clientId = googleAuthOptions.clientId!;
    // devPrint('signing in...rest_web');
    try {
      _closeClient();
      var clientId = googleAuthOptions.clientId!;
      // var authClientId = ClientId(clientId, googleAuthOptions.clientSecret);
      /*
      var responseCode = await auth_browser.requestAuthorizationCode(
          clientId: clientId, scopes: scopes);
      
      devPrint(responseCode.toString());
      var accessCredentials = await obtainAccessCredentialsViaCodeExchange(
          Client(), authClientId, responseCode.code);
      var authClient = auth_browser.autoRefreshingClient(
          authClientId, accessCredentials, Client());
          
                 */
      var accessCredentials = await auth_browser.requestAccessCredentials(
          clientId: clientId, scopes: scopes);
      var authClient = auth_browser.authenticatedClient(
          Client(), accessCredentials,
          closeUnderlyingClient: true);

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

      // devPrint(jsonPretty(person.toJson()));
      // devPrint(auth.currentUser);

      var result = AuthSignInResultRest(client: authClient, provider: this)
        ..hasInfo = true
        ..credential = UserCredentialRestImpl(
            AuthCredentialRestImpl(providerId: providerId),
            UserRest(
                client: authClient,
                uid: person.id!,
                emailVerified: person.verifiedEmail ?? false,
                provider: this));
      () async {
        var user = toUserRest(authClient.credentials);
        // devPrint('adding user $user ($currentUserController)');
        setCurrentUser(user);
      }()
          .unawait();
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

abstract class GoogleAuthProviderRestWeb implements GoogleRestAuthProvider {
  factory GoogleAuthProviderRestWeb({required GoogleAuthOptions options}) =>
      GoogleAuthProviderRestImpl(options);
}

Future<GoogleAuthOptions?> loadGoogleAuthOptions() async {
  // Load javascript
  // await loadFirebaseJs();
  var client = BrowserClient();

  // Load client info
  try {
    var sample = await client.read(Uri.parse('sample.local.config.yaml'));

    try {
      var local = await client.read(Uri.parse('local.config.yaml'));
      var map = (loadYaml(local) as Map).cast<String, Object?>();
      var options = GoogleAuthOptions.fromMap(map);
      if (options.projectId == null) {
        print('Missing "projectId" in local.config.yaml');
        return null;
      }
      return options;
    } catch (e) {
      print(e);
      print('Cannot find local.config.yaml');
      print(
          'Create it from the sample.local.config.yaml file with your firebase information');
      print(sample);
    }
  } catch (e) {
    print(e);
    print('Cannot find sample.local.config.yaml');
    print('Make sure to run the test using something like: ');
    print('  pub run build_runner test --fail-on-severe -- -p chrome');
  }
  return null;
}
