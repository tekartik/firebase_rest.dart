// Token data
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_rest/src/firebase_rest_identity.dart';

/// Get app options from access credentials
FirebaseAppOptionsRest getAppOptionsFromAccessCredentials(
  Client client,
  AccessCredentials accessCredentials, {
  List<String>? scopes,
  String? projectId,
  required FirebaseAppOptions? originalOptions,
}) {
  var authClient = authenticatedClient(client, accessCredentials);
  var appOptions = AppOptionsRest(
    client: authClient,
    identifyServiceAccount: FirebaseRestIdentifyServiceAccountImpl(),
    apiKey: originalOptions?.apiKey,
    storageBucket: originalOptions?.storageBucket,
  )..projectId = projectId;
  return appOptions;
}

/// Get app options from access token
FirebaseAppOptions getAppOptionsFromAccessToken(
  Client client,
  String token, {
  required String projectId,
  required List<String> scopes,
  required FirebaseAppOptions? originalOptions,
}) {
  // expiry is ignored in request
  var accessToken = AccessToken('Bearer', token, DateTime.now().toUtc());
  var accessCredentials = AccessCredentials(accessToken, null, scopes);
  return getAppOptionsFromAccessCredentials(
    client,
    accessCredentials,
    projectId: projectId,
    originalOptions: originalOptions,
  );
}
