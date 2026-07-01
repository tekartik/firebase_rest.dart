@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_storage_rest/storage_rest.dart';
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
  late App app;
  late Storage storage;
  late Bucket bucket;
  group('firebase_storage_rest_emulator', () {
    late FirebaseEmulator emulator;
    setUpAll(() async {
      emulator = await _emulatorService.start(
        options: FirebaseEmulatorOptions(
          projectId: fbProjectId,
          onlyStorage: true,
          debug: false,
        ),
      );
      app = firebaseRest.initializeApp(
        options: FirebaseAppOptions(
          projectId: fbProjectId,
          apiKey: 'dummy',
          storageBucket: storageBucket,
        ),
      );
      var storageRest = storageServiceRest.storage(app) as StorageRest;
      await storageRest.useStorageEmulator('localhost', 9199);
      storage = storageRest;
      bucket = storage.bucket(storageBucket);
    });

    tearDownAll(() async {
      await app.delete();
      await emulator.stop();
    });

    test('file not exists', () async {
      var file = bucket.file('dummy-file-that-should-not-exists');
      expect(await file.exists(), isFalse);
    });

    test('write_read_delete', () async {
      var file = bucket.file('file.to_delete.txt');
      await file.writeAsString('simple content');
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), 'simple content');
      await file.delete();
      expect(await file.exists(), isFalse);
    });

    test('write_read_content_type', () async {
      var file = bucket.file('with_meta/file0.txt');
      await file.upload(
        utf8.encode('storage_with_meta_test'),
        options: StorageUploadFileOptions(contentType: 'text/plain'),
      );
      var metadata = await file.getMetadata();
      expect(metadata.contentType, 'text/plain');
      expect(
        metadata.size,
        greaterThanOrEqualTo('storage_with_meta_test'.length),
      );
    });

    test('write_read_detected_content_type', () async {
      var file = bucket.file('with_detected_meta/file0.txt');
      await file.upload(utf8.encode('storage_with_meta_detected_test'));
      var metadata = await file.getMetadata();
      expect(metadata.contentType, 'text/plain');
    });

    test('list_files', () async {
      var content = 'storage_list_files_test';
      await bucket.file('test/list_files/yes/file1.txt').writeAsString(content);
      await bucket
          .file('test/list_files/yes/sub/file2.txt')
          .writeAsString(content);

      var response = await bucket.getFiles(
        GetFilesOptions(prefix: 'test/list_files/yes'),
      );
      var names = response.files.map((e) => e.name).toList()..sort();
      expect(names, [
        'test/list_files/yes/file1.txt',
        'test/list_files/yes/sub/file2.txt',
      ]);
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
