// ignore_for_file: avoid_print

@TestOn('vm')
library;

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  var context = await authRestSetup();
  var firebase = firebaseRest;

  AppOptions? accessTokenAppOptions;
  if (context != null) {
    group('auth_rest', () {
      test('factory', () {
        expect(firebaseAuthServiceRest.supportsListUsers, isFalse);
        expect(firebaseAuthServiceRest.supportsCurrentUser, isFalse);
      });

      runAuthTests(firebase: firebase, authService: firebaseAuthServiceRest);
      group('access_token', () {
        runAuthTests(
          firebase: firebase,
          authService: firebaseAuthServiceRest,
          name: 'access_token',
          options: accessTokenAppOptions,
        );
      });
      runAuthTests(firebase: firebase, authService: firebaseAuthServiceRest);

      group('auth', () {
        late App app;
        late FirebaseAuthRest auth;

        setUpAll(() async {
          app = firebase.initializeApp(
            name: 'auth',
          ); //, options: context?.options);
          auth = firebaseAuthServiceRest.auth(app);
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
          var userRecords = await auth.getUsers([
            userId,
            'NX8geaeHWCcibyp2YWeyU7UqEtN2',
          ]);
          if (userRecords.isNotEmpty) {
            for (var i = 0; i < userRecords.length; i++) {
              var userRecord = userRecords[i];
              expect(userRecord.displayName, isNotNull);
              print('userRecords[$i]: $userRecord');
            }
          }
          //expect(true, isFalse);
        });

        // The service account is an admin: listing and looking up by email
        // work whatever the service says, see the admin group.
        test('listUsers', () async {
          await checkListUsers(auth);
        });

        test('getUserByEmail', () async {
          expect(await auth.getUserByEmail(unknownEmail()), isNull);
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
              fail('should fail');
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

/// An email no account has.
String unknownEmail() =>
    'nobody-${DateTime.now().microsecondsSinceEpoch}@example.com';

/// Lists the users two by two, at most three pages: no user listed twice,
/// each found again by uid and by email.
Future<void> checkListUsers(FirebaseAuth auth) async {
  var uids = <String>{};
  String? pageToken;
  for (var page = 0; page < 3; page++) {
    var result = await auth.listUsers(maxResults: 2, pageToken: pageToken);
    expect(result.users.length, lessThanOrEqualTo(2));
    for (var user in result.users.nonNulls) {
      expect(uids.add(user.uid), isTrue, reason: 'listed twice ${user.uid}');
      expect((await auth.getUser(user.uid))!.uid, user.uid);
      var email = user.email;
      if (email != null) {
        expect((await auth.getUserByEmail(email))!.uid, user.uid);
      }
    }
    pageToken = result.pageToken;
    if (pageToken == null) {
      break;
    }
  }
  print('listed ${uids.length} users${pageToken == null ? '' : ' (and more)'}');
}
