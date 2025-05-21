import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:tekartik_firebase/firebase_admin.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_rest/src/firebase_rest_identity.dart';

import 'firebase_rest.dart';

/// Firebase admin credential rest implementation
class FirebaseAdminCredentialRestImpl implements FirebaseAdminCredentialRest {
  /// Service account credentials
  late ServiceAccountCredentials serviceAccountCredentials;

  /// Scopes
  final List<String> scopes;
  @override
  AuthClient? authClient;
  @override
  AppOptionsRest? appOptions;

  /// Project id
  @override
  late String projectId;

  /// from service account json string
  factory FirebaseAdminCredentialRestImpl.fromServiceAccountJson(
    String serviceAccountJson, {
    List<String>? scopes,
  }) => FirebaseAdminCredentialRestImpl.fromServiceAccountMap(
    jsonDecode(serviceAccountJson) as Map,
    scopes: scopes,
  );

  /// from service account map
  FirebaseAdminCredentialRestImpl.fromServiceAccountMap(
    Map serviceAccountMap, {
    List<String>? scopes,
  }) : scopes = scopes ?? firebaseBaseScopes {
    projectId = serviceAccountMap['project_id'].toString();

    serviceAccountCredentials = ServiceAccountCredentials.fromJson(
      serviceAccountMap,
    );
  }

  Future<FirebaseAdminAccessToken>? _accessToken;

  /// Get the auto refreshing auth client
  @override
  Future<AuthClient> initAuthClient() async {
    authClient = await clientViaServiceAccount(
      serviceAccountCredentials,
      scopes,
    );
    appOptions = AppOptionsRest(
      client: authClient,
      identifyServiceAccount: FirebaseRestIdentifyServiceAccountImpl(),
    )..projectId = projectId;

    return authClient!;
  }

  @override
  Future<FirebaseAdminAccessToken> getAccessToken() =>
      _accessToken ??= () async {
        var client = Client();
        var accessCreds = await obtainAccessCredentialsViaServiceAccount(
          serviceAccountCredentials,
          scopes,
          client,
        );
        var accessToken = accessCreds.accessToken;
        authClient = authenticatedClient(client, accessCreds);
        appOptions = AppOptionsRest(
          client: authClient,
          identifyServiceAccount: FirebaseRestIdentifyServiceAccountImpl(),
        )..projectId = projectId;
        return FirebaseAdminAccessTokenRest(data: accessToken.data);
      }();
  /*

    var authClient = authenticatedClient(client, accessCreds);
    var appOptions = AppOptionsRest(authClient: authClient)
      ..projectId = jsonData['project_id']?.toString();
    var context = Context()
      ..client = client
      ..accessToken = accessToken
      ..authClient = authClient
      ..options = appOptions;
  }

 */
  @override
  String toString() {
    return 'FirebaseRest($projectId)';
  }
}

/// Create a new firebase admin credential rest from a service account json
FirebaseAdminCredentialRest firebaseAdminCredentialsFromServiceAccountJson(
  String serviceAccountJson, {
  List<String>? scopes,
}) {
  return FirebaseAdminCredentialRestImpl.fromServiceAccountJson(
    serviceAccountJson,
    scopes: scopes,
  );
}

/// Create a new firebase admin credential rest from a service account map
FirebaseAdminCredentialRest firebaseAdminCredentialsFromServiceAccountMap(
  Map serviceAccountMap, {
  List<String>? scopes,
}) {
  return FirebaseAdminCredentialRestImpl.fromServiceAccountMap(
    serviceAccountMap,
    scopes: scopes,
  );
}
