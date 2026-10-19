@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

/// A fake identity toolkit admin api (no network): the account info and the
/// account download, with the `lastRefreshAt` the typed v3 api drops.
MockClient _fakeIdentityToolkitAdmin() {
  http.Response json(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
  var users = [
    {
      'localId': 'uid1',
      'email': 'user1@example.com',
      'createdAt': '1792447045900',
      'lastLoginAt': '1792447045900',
      'lastRefreshAt': '2026-10-19T21:57:25.977Z',
    },
    // Never refreshed.
    {'localId': 'uid2', 'createdAt': '1792447045900'},
  ];
  return MockClient((request) async {
    var path = request.url.path;
    if (path.endsWith('/getAccountInfo')) {
      var body = jsonDecode(request.body) as Map;
      var localIds = (body['localId'] as List?)?.cast<String>();
      var emails = (body['email'] as List?)?.cast<String>();
      return json({
        'users': users
            .where(
              (user) =>
                  (localIds?.contains(user['localId']) ?? false) ||
                  (emails?.contains(user['email']) ?? false),
            )
            .toList(),
      });
    }
    if (path.endsWith('/downloadAccount')) {
      return json({'users': users});
    }
    return http.Response('unexpected $path', 404);
  });
}

void main() {
  var options = FirebaseAppOptions(projectId: 'admin_mock_test');

  test('user records lastRefreshTime', () async {
    await http.runWithClient(() async {
      var app = firebaseRest.initializeApp(
        options: options,
        name: 'admin_mock',
      );
      try {
        var auth = firebaseAuthServiceRestAdmin.auth(app);
        var user = (await auth.getUser('uid1'))!;
        expect(user.metadata!.lastRefreshTime, '2026-10-19T21:57:25.977Z');
        expect(user.metadata!.lastSignInTime, '2026-10-19T21:57:25.900Z');

        user = (await auth.getUserByEmail('user1@example.com'))!;
        expect(user.metadata!.lastRefreshTime, '2026-10-19T21:57:25.977Z');

        var users = await auth.getUsers(['uid1', 'uid2']);
        expect(users.map((user) => user.metadata!.lastRefreshTime), [
          '2026-10-19T21:57:25.977Z',
          isNull,
        ]);

        var result = await auth.listUsers();
        expect(result.users.map((user) => user!.metadata!.lastRefreshTime), [
          '2026-10-19T21:57:25.977Z',
          isNull,
        ]);
      } finally {
        await app.delete();
      }
    }, _fakeIdentityToolkitAdmin);
  });
}
