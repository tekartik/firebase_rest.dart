@TestOn('vm')
library;

import 'dart:io';

import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

var defaultRegion = 'europe-west1';
var _emulatorService = FirebaseEmulatorService(path: 'emulator');
Future main() async {
  debugFirestoreRest = true;

  // needed for memory
  skipConcurrentTransactionTests = true;
  skipFirestoreTransactionTests = true;
  if (await _emulatorService.isSupported()) {
    stdout.writeln('firebase emulator is supported');
  } else {
    test('not_supported', () {}, skip: 'firebase emulator is not supported');
    return;
  }

  final fbProjectId = await _emulatorService.getProjectId();
  late FirebaseEmulator emulator;
  emulator = await _emulatorService.start(
    options: FirebaseEmulatorOptions(
      projectId: fbProjectId,
      onlyAuth: true,
      onlyFirestore: true,
      debug: false,
    ),
  );
  var app = await firebaseRest.initializeAppAsync(
    options: FirebaseAppOptions(projectId: fbProjectId, apiKey: 'dummy'),
  );
  var auth = firebaseAuthServiceRest.auth(app);
  var firestoreService = firestoreServiceRest;
  var firestore = firestoreService.firestore(app);
  await auth.useAuthEmulator('localhost', 9099);
  await firestore.useFirestoreEmulator('localhost', 8080);

  group('firebase_functions_dart', () {
    setUpAll(() async {
      await auth.signInOrUpWithEmailAndPassword(
        email: 'test@mail.com',
        password: 'test1234',
      );
    });

    tearDownAll(() async {
      await app.delete();
    });

    test('simple', () {});

    runFirestoreAppTests(
      app: app,
      firestoreService: firestoreService,
      testContext: FirestoreTestContext(),
    );
    tearDownAll(() async {
      await emulator.stop();
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
