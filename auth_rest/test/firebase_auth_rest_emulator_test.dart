@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_auth_test/auth_sign_in_delete_test_runner.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

var defaultRegion = 'europe-west1';
var _emulatorService = FirebaseEmulatorService(path: 'emulator');
Future main() async {
  if (await _emulatorService.isSupported()) {
    stdout.writeln('firebase emulator is supported');
  } else {
    test('not_supported', () {}, skip: 'firebase emulator is not supported');
    return;
  }

  final fbProjectId = await _emulatorService.getProjectId();
  late FirebaseAuthRest auth;
  group('firebase_functions_dart', () {
    late FirebaseEmulator emulator;
    setUpAll(() async {
      emulator = await _emulatorService.start(
        options: FirebaseEmulatorOptions(
          projectId: fbProjectId,
          onlyAuth: true,
          debug: false,
        ),
      );
      var app = await firebaseRest.initializeAppAsync(
        options: FirebaseAppOptions(projectId: fbProjectId, apiKey: 'dummy'),
      );
      auth = firebaseAuthServiceRest.auth(app);
      await auth.useAuthEmulator('localhost', 9099);
    });

    tearDownAll(() async {
      await auth.app.delete();
    });

    /// Most basic
    test('user', () async {
      var email = 'test@mail.com';
      var password = 'test1234';
      await auth.signOut();
      expect(auth.currentUser?.uid, isNull);
      var credential = await auth.signInOrUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      expect(auth.currentUser!.uid, credential.user.uid);
    });
    test('signInWithIdp google', () async {
      await auth.signOut();
      // The emulator takes an unsigned id token.
      var idToken = jsonEncode({
        'sub': 'idp-test-google-id',
        'email': 'idp@gmail.com',
        'email_verified': true,
        'name': 'Idp Test',
      });
      var credential = await auth.signInWithIdp(idToken: idToken);
      var uid = credential.user.uid;
      expect(auth.currentUser!.uid, uid);
      expect(credential.user.email, 'idp@gmail.com');
      expect(credential.user.emailVerified, isTrue);
      expect(credential.user.displayName, 'Idp Test');
      // A firebase id token, renewable.
      expect(
        await (auth.currentUser! as UserInfoWithIdToken).getIdToken(
          forceRefresh: true,
        ),
        isNotEmpty,
      );

      // The same firebase user next time.
      await auth.signOut();
      expect(auth.currentUser, isNull);
      credential = await auth.signInWithIdp(idToken: idToken);
      expect(credential.user.uid, uid);
      await auth.signOut();
    });
    var email = 'delete@gmail.com';
    var password = 'test1234';
    firebaseAuthSignInDeleteTests(
      getAuth: () => auth,
      email: email,
      password: password,
    );

    tearDownAll(() async {
      await emulator.stop();
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
