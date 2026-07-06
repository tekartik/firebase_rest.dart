@TestOn('vm')
library;

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
