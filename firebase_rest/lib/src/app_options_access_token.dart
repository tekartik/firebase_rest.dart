// Token data
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

/// Get app options from access credentials
FirebaseAppOptions getAppOptionsFromAccessCredentials(
    Client client, AccessCredentials accessCredentials,
    {List<String>? scopes, String? projectId}) {
  var authClient = authenticatedClient(client, accessCredentials);
  var appOptions = AppOptionsRest(client: authClient)..projectId = projectId;
  return appOptions;
}

/// Get app options from access token
FirebaseAppOptions getAppOptionsFromAccessToken(Client client, String token,
    {required String projectId, required List<String> scopes}) {
  // expiry is ignored in request
  var accessToken = AccessToken('Bearer', token, DateTime.now().toUtc());
  var accessCredentials = AccessCredentials(accessToken, null, scopes);
  return getAppOptionsFromAccessCredentials(client, accessCredentials,
      projectId: projectId);
}
