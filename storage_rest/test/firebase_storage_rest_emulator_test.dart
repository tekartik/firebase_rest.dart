@TestOn('vm')
library;

import 'dart:io';

import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_storage_rest/storage_rest.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

var _emulatorService = FirebaseEmulatorService(path: 'emulator');
Future main() async {
  if (await _emulatorService.isSupported()) {
    stdout.writeln('firebase emulator is supported');
  } else {
    test('not_supported', () {}, skip: 'firebase emulator is not supported');
    return;
  }

  final fbProjectId = await _emulatorService.getProjectId();
  var storageBucket = '$fbProjectId.appspot.com';
  late FirebaseEmulator emulator;

  group('firebase_storage_rest_emulator', () {
    setUpAll(() async {
      emulator = await _emulatorService.start(
        options: FirebaseEmulatorOptions(
          projectId: fbProjectId,
          onlyStorage: true,
          debug: false,
        ),
      );
    });

    tearDownAll(() async {
      await emulator.stop();
    });

    runStorageTests(
      firebase: firebaseRest,
      storageService: firebaseStorageServiceRest,
      options: FirebaseAppOptions(
        projectId: fbProjectId,
        apiKey: 'dummy',
        storageBucket: storageBucket,
      ),
      storageOptions: TestStorageOptions(
        bucket: storageBucket,
        skipDefaultBucketExists: true,
      ),
    );
  }, timeout: const Timeout(Duration(minutes: 5)));

  // `runStorageTests` creates the app and its storage instance synchronously
  // above (group()/test() bodies only register, they don't run yet), so the
  // just-created storage instance can still be switched to the emulator here
  // before the test runner actually starts executing tests.
  var app = firebaseRest.app();
  var storage = firebaseStorageServiceRest.storage(app) as FirebaseStorageRest;
  await storage.useStorageEmulator('localhost', 9199);
}
