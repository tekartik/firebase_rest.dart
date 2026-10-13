@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

/// A fake identity toolkit (no network): password sign in and the account
/// info, with the email verified once [emailVerified] returns true.
MockClient _fakeIdentityToolkit({required bool Function() emailVerified}) {
  http.Response json(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
  return MockClient((request) async {
    var path = request.url.path;
    if (path.endsWith('/verifyPassword')) {
      return json({
        'localId': 'uid1',
        'email': 'user@example.com',
        'idToken': 'id_token1',
        'refreshToken': 'refresh_token1',
        'expiresIn': '3600',
      });
    }
    if (path.endsWith('/getAccountInfo')) {
      return json({
        'users': [
          {
            'localId': 'uid1',
            'email': 'user@example.com',
            'displayName': 'User 1',
            'emailVerified': emailVerified(),
          },
        ],
      });
    }
    return http.Response('unexpected $path', 404);
  });
}

void main() {
  var options = FirebaseAppOptions(
    projectId: 'reload_test',
    apiKey: 'fake_api_key',
  );

  test('reloadCurrentUser updates and emits the current user', () async {
    var verified = false;
    var persistence = FirebaseRestAuthPersistenceMemory();
    var authService = FirebaseAuthServiceRest(persistence: persistence);
    await http.runWithClient(() async {
      var app = firebaseRest.initializeApp(options: options, name: 'reload');
      try {
        var auth = authService.auth(app);
        await auth.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password1',
        );
        expect(auth.currentUser!.emailVerified, isFalse);

        var users = <User?>[];
        var subscription = auth.onCurrentUser.listen(users.add);
        await Future<void>.delayed(Duration.zero);

        verified = true;
        var user = await auth.reloadCurrentUser();
        await Future<void>.delayed(Duration.zero);
        expect(user!.emailVerified, isTrue);
        expect(auth.currentUser!.emailVerified, isTrue);
        expect(users.last!.emailVerified, isTrue);
        // The account info, same session (tokens kept).
        expect(auth.currentUser!.displayName, 'User 1');
        expect(
          await (auth.currentUser! as UserInfoWithIdToken).getIdToken(),
          'id_token1',
        );
        // Not awaited: cancelling an onCurrentUser subscription of the rest
        // auth does not complete (before this change too).
        unawaited(subscription.cancel());
      } finally {
        await app.delete();
      }

      // Persisted: restored verified.
      app = firebaseRest.initializeApp(options: options, name: 'reload');
      try {
        var auth = authService.auth(app);
        var restored = await auth.onCurrentUser.first;
        expect(restored!.uid, 'uid1');
        expect(restored.emailVerified, isTrue);
      } finally {
        await app.delete();
      }
    }, () => _fakeIdentityToolkit(emailVerified: () => verified));
  });
}
