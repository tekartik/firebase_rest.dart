@TestOn('vm')
library;

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/utils/json_utils.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/import.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_rest/test/setup.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  var context = await authRestSetup(useEnv: true);
  var firebase = firebaseRest;

  if (context == null) {
    test('no env setup available', () {});
  } else {
    if (runningOnGithub && !isGithubActionsUbuntuAndDartStable()) {
      test('Skip on github for other than ubuntu and dart stable', () {
        print('githubActionsPrefix: $githubActionsPrefix');
      });
      return;
    }
    group('auth_rest', () {
      test('setup', () {
        print('Using firebase:');
        print('projectId: ${context.options!.projectId}');
      });
      test('factory', () {
        expect(authServiceRest.supportsListUsers, isFalse);
        expect(authServiceRest.supportsCurrentUser, isTrue);
      });

      runAuthTests(
          firebase: firebase,
          authService: authServiceRest,
          options: context.options);
      group('access_token', () {
        runAuthTests(
            firebase: firebase,
            authService: authServiceRest,
            name: 'access_token',
            options: context.options);
      });

      group('auth', () {
        late App app;
        late AuthRest auth;

        setUpAll(() async {
          app = firebase.initializeApp(
              options: context.options,
              name: 'auth'); //, options: context?.options);
          auth = authServiceRest.auth(app) as AuthRest;
        });

        tearDownAll(() {
          return app.delete();
        });

        test('accessToken', () {
          // print(context.accessToken.data);
        });

        test('getUserInfo', () async {
          var user = auth.currentUser;
          expect(user, isNull);
          // devPrint('user: $user');
          var userId = 'gpt1QKVyJMcLHh2MM2x4THAaQW63';
          var userRecord = await auth.getUser(userId);
          if (userRecord != null) {
            expect(userRecord.displayName, isNotNull);
            print('userRecord: $userRecord');
          }
          //expect(true, isFalse);
        });

        test('getUsers', () async {
          var user = auth.currentUser;
          expect(user, isNull);
          var userId = 'gpt1QKVyJMcLHh2MM2x4THAaQW63';
          var userRecords =
              await auth.getUsers([userId, 'NX8geaeHWCcibyp2YWeyU7UqEtN2']);
          if (userRecords.isNotEmpty) {
            for (var i = 0; i < userRecords.length; i++) {
              var userRecord = userRecords[i];
              expect(userRecord.displayName, isNotNull);
              print('userRecords[$i]: $userRecord');
            }
          }
          //expect(true, isFalse);
        });

        test('listUsers', () async {
          try {
            var user = (await auth.listUsers(maxResults: 1)).users.first!;
            print(userRecordToJson(user));
            fail('should fail');
          } on UnsupportedError catch (_) {}
        });

        test('getUserByEmail', () async {
          try {
            expect(
                (await auth.getUserByEmail('admin@example.com'))!.displayName,
                'admin');
            expect((await auth.getUserByEmail('user@example.com'))!.displayName,
                'user');
            fail('should fail');
          } on UnsupportedError catch (_) {}
        });

        group('currentUser', () {
          test('currentUser', () async {
            var user = auth.currentUser;
            expect(user, isNull);
            print('currentUser: $user');
            try {
              user = await auth.onCurrentUser.first;
              print('currentUser: $user');
              if (user != null) {
                expect(user, const TypeMatcher<UserInfoWithIdToken>());
              }
              //fail('should fail');
            } on UnsupportedError catch (_) {}
          });
        });

        test('idToken', () async {
          // if (context.authClient != null) {
          /*
          var provider = AuthLocalProvider();
          var result = await auth.signIn(provider,
              options: AuthLocalSignInOptions(localAdminUser));
          var user = result.credential.user;
          var idToken = await (user as UserInfoWithIdToken).getIdToken();
          var decoded = await auth.verifyIdToken(idToken);
          expect(decoded.uid, localAdminUser.uid);

           */
        });
      });
    });
  }
}
