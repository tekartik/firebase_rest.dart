import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/identitytoolkit/v3.dart'
    hide UserInfo;

import 'auth_rest_provider.dart';
import 'identitytoolkit/v3.dart';

/// Convert a rest user to a user record
Future<UserRecord?> getUser(AuthClient client, String uid) async {
  var request = IdentitytoolkitRelyingpartyGetAccountInfoRequest()
  //  ..localId = [uid]
  ;
  if (debugFirebaseAuthRest) {
    // ignore: avoid_print
    print('getAccountInfoRequest2: ${jsonPretty(request.toJson())}');
  }
  var identitytoolkitApi = IdentityToolkitApi(client);
  var result = await identitytoolkitApi.relyingparty.getAccountInfo(request);
  if (debugFirebaseAuthRest) {
    // ignore: avoid_print
    print('getAccountInfo: ${jsonPretty(result.toJson())}');
  }
  if (result.users?.isNotEmpty ?? false) {
    var restUserInfo = result.users!.first;
    return toUserRecord(restUserInfo);
  }
  return null;
}

/// Google rest auth provider mixin
mixin GoogleRestAuthProviderMixin implements GoogleRestAuthProvider {
  // must be initialized.
  /// Google auth options
  late final GoogleAuthOptions googleAuthOptions;

  /// Scopes
  late final List<String> scopes;

  /// Current user
  UserRest? currentUser;

  /// Client
  AuthClient get client;

  /// Api key
  String get apiKey;

  final _scopes = <String>[];

  @override
  String get providerId => 'googleapis_auth';

  /// Adds additional OAuth 2.0 scopes that you want to request from the
  /// authentication provider.
  @override
  void addScope(String scope) {
    _scopes.add(scope);
  }

  @override
  Future<String> getIdToken({bool? forceRefresh}) async {
    /*
    devPrint(
        'getIdToken($forceRefresh) apiKey: $apiKey ${client.credentials.accessToken}');
    /*
    var secureTokenApi = SecureTokenApi(apiKey: apiKey, client: client);
    var token = await secureTokenApi.getIdToken(forceRefresh: forceRefresh);

     */
    var identitytoolkitApi = IdentityToolkitApi(client);
    var response = await identitytoolkitApi.relyingparty
        .verifyCustomToken(IdentitytoolkitRelyingpartyVerifyCustomTokenRequest(
      returnSecureToken: true,
    ));
    return response.idToken!;

     */
    return client.credentials.accessToken.data;
  }
}

/// Google rest auth provider
abstract class GoogleRestAuthProvider implements AuthProviderRest {
  /// Add scope
  void addScope(String scope);
}

/// Google auth options
class GoogleAuthOptions {
  /// The developer key needed for the picker API
  String? developerKey;

  /// The Client ID obtained from the Google Cloud Console.
  String? clientId;

  /// The Client Secret obtained from the Google Cloud Console.
  String? clientSecret;

  /// The API key for auth
  String? apiKey;

  /// Project ID
  String? projectId;

  /// Constructor
  GoogleAuthOptions({
    this.developerKey,
    this.clientId,
    this.clientSecret,
    this.apiKey,
    this.projectId,
  });

  /// From map
  GoogleAuthOptions.fromMap(Map map) {
    // Web (?)
    developerKey = map['developerKey']?.toString();
    // web/io
    apiKey = (map['apiKey'] ?? map['api_key'])?.toString();
    // web/io
    clientId = (map['clientId'] ?? map['client_id'])?.toString();
    // Web (?)
    clientSecret = (map['clientSecret'] ?? map['client_secret'])?.toString();
    // web/io
    projectId = (map['projectId'] ?? map['project_id'])?.toString();
  }

  @override
  String toString() => {
    'developerKey': developerKey,
    'clientId': clientId,
    'clientSecret': clientSecret,
    'projectId': projectId,
    'apiKey': apiKey,
  }.toString();
}

/// Auth sign in result rest
class AuthSignInResultRest implements AuthSignInResult {
  /// Provider
  final AuthProviderRest provider;

  /// Client
  final AuthClient client;
  @override
  late UserCredential credential;

  @override
  late bool hasInfo;

  /// Constructor
  AuthSignInResultRest({required this.provider, required this.client});

  @override
  String toString() => 'Result($hasInfo, $credential)';
}
