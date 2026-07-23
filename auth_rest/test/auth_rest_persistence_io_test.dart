@TestOn('vm')
library;

import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:test/test.dart';

import 'src/auth_rest_persistence_test_runner.dart';

void main() {
  group('file', () {
    var index = 0;
    runFirebaseRestAuthPersistenceTests(
      () => FirebaseRestAuthPersistenceFile(
        fs: fileSystemMemory,
        directoryPath: 'auth_rest_persistence_test_${index++}',
      ),
    );
  });

  group('onPersistence (generic file)', () {
    var index = 0;
    runFirebaseRestAuthPersistenceTests(
      () => FirebaseRestAuthPersistenceOnPersistence(
        TekartikFirebasePersistenceFile(
          fs: fileSystemMemory,
          directoryPath: 'auth_rest_persistence_on_file_test_${index++}',
        ),
      ),
    );
  });

  group('FirebaseRestAuthPersistenceFile default directory', () {
    test('defaults to .local', () {
      var persistence = FirebaseRestAuthPersistenceFile(fs: fileSystemMemory);
      var fileBacked =
          persistence.persistence as TekartikFirebasePersistenceFile;
      expect(fileBacked.directoryPath, '.local');
    });
  });
}
