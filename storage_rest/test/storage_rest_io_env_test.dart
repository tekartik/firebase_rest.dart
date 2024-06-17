@TestOn('vm')
library tekartik_firebase_storage_rest.storage_rest_io_test;

import 'package:process_run/shell.dart';
import 'package:tekartik_firebase_storage_rest/storage_rest.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  var context = await setup(useEnv: true);
  var testRootPath =
      shellEnvironment['TEKARTIK_FIREBASE_STORAGE_REST_TEST_ROOT_PATH'];
  test('env', () {
    print('TEKARTIK_FIREBASE_STORAGE_REST_TEST_ROOT_PATH: $testRootPath');
  });
  if (context != null) {
    group('rest_io', () {
      // Temp
      //context = null;

      test('setup', () {
        print('Using firebase project: ${context.options!.projectId}');
      });
      var firebase = firebaseRest;
      group('all', () {
        runStorageTests(
            firebase: firebase,
            storageService: storageServiceRest,
            options: context.options,
            storageOptions:
                TestStorageOptions(bucket: context.options!.storageBucket));
      });
    });
  }
}
