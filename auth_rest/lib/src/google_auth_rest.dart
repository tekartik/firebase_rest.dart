import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/identitytoolkit/v3.dart'
    hide UserInfo;

import 'identitytoolkit/v3.dart';

Future<UserRecord?> getUser(AuthClient client, String uid) async {
  var request = IdentitytoolkitRelyingpartyGetAccountInfoRequest()
      //  ..localId = [uid]
      ;
  if (debugRest) {
    print('getAccountInfoRequest2: ${jsonPretty(request.toJson())}');
  }
  var identitytoolkitApi = IdentityToolkitApi(client);
  var result = await identitytoolkitApi.relyingparty.getAccountInfo(request);
  if (debugRest) {
    print('getAccountInfo: ${jsonPretty(result.toJson())}');
  }
  if (result.users?.isNotEmpty ?? false) {
    var restUserInfo = result.users!.first;
    return toUserRecord(restUserInfo);
  }
  return null;
}

mixin GoogleRestAuthProviderMixin implements GoogleRestAuthProvider {
  // must be initialized.
  late final GoogleAuthOptions googleAuthOptions;
  late final List<String> scopes;
  UserRest? currentUser;

  StreamController<UserRest?>? currentUserController;

  void setCurrentUser(User? user) {
    currentUser = user as UserRest?;

    var ctlr = currentUserController;
    // devPrint('currentUserController $ctlr');
    if (ctlr != null) {
      ctlr.add(user);
    }
  }

  AuthClient get client;

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

abstract class GoogleRestAuthProvider implements AuthProviderRest {
  void addScope(String scope);
}

class GoogleAuthOptions {
  // The developer key needed for the picker API
  String? developerKey;

  // The Client ID obtained from the Google Cloud Console.
  String? clientId;

  // The Client Secret obtained from the Google Cloud Console.
  String? clientSecret;

  // The API key for auth
  String? apiKey;
  String? projectId;

  GoogleAuthOptions(
      {this.developerKey,
      this.clientId,
      this.clientSecret,
      this.apiKey,
      this.projectId});

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
        'apiKey': apiKey
      }.toString();
}

class AuthSignInResultRest implements AuthSignInResult {
  final AuthProviderRest provider;
  final AuthClient client;
  @override
  late UserCredential credential;

  @override
  late bool hasInfo;

  AuthSignInResultRest({required this.provider, required this.client});

  @override
  String toString() => 'Result($hasInfo, $credential)';
}
