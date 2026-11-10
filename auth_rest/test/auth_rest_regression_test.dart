@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

/// A fake id token (unsigned jwt) holding [claims].
String _fakeIdToken(Map<String, Object?> claims) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part(claims)}.signature';
}

/// A fake identity toolkit (no network) signing in a verified account.
MockClient _fakeIdentityToolkit() {
  var idToken = _fakeIdToken({
    'user_id': 'uid1',
    'sub': 'uid1',
    'email': 'user@example.com',
    'email_verified': true,
    'exp':
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000,
  });
  return MockClient((request) async {
    if (request.url.path.endsWith('/verifyPassword')) {
      return http.Response(
        jsonEncode({
          'localId': 'uid1',
          'email': 'user@example.com',
          'idToken': idToken,
          'refreshToken': 'refresh_token1',
          'expiresIn': '3600',
          'registered': true,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response('unexpected ${request.url.path}', 404);
  });
}

void main() {
  group('auth_rest regression', () {
    test('a verified account is verified once signed in', () async {
      await http.runWithClient(() async {
        var app = firebaseRest.initializeApp(
          options: FirebaseAppOptions(
            projectId: 'email_verified_test',
            apiKey: 'fake_api_key',
          ),
          name: 'email_verified',
        );
        try {
          var auth = FirebaseAuthServiceRest().auth(app);
          var credential = await auth.signInWithEmailAndPassword(
            email: 'user@example.com',
            password: 'password1',
          );
          expect(credential.user.emailVerified, isTrue);
          expect(auth.currentUser!.emailVerified, isTrue);
        } finally {
          await app.delete();
        }
      }, _fakeIdentityToolkit);
    });

    test('the app client is kept without a signed in user', () async {
      // An app initialized with an authenticated client (a service account
      // one for an admin app).
      var appClient = MockClient((request) async => http.Response('{}', 200));
      var app =
          firebaseRest.initializeApp(
                options: AppOptionsRest(client: appClient)
                  ..projectId = 'app_client_test',
                name: 'app_client',
              )
              as FirebaseAppRest;
      try {
        var auth = firebaseAuthServiceRestAdmin.auth(app);
        expect(await auth.onCurrentUser.first, isNull);
        expect(app.client, same(appClient));
        await auth.signOut();
        expect(app.client, same(appClient));
        expect(app.apiClient, same(appClient));
      } finally {
        await app.delete();
      }
    });
  });
}
