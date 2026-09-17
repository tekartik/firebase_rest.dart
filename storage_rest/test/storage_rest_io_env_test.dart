// ignore_for_file: avoid_print

@TestOn('vm')
library;

import 'package:process_run/shell.dart';
import 'package:tekartik_firebase_rest/test/setup.dart';
import 'package:tekartik_firebase_storage_rest/storage_rest.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  var context = await storageRestSetup(useEnv: true);
  var testRootPath =
      shellEnvironment['TEKARTIK_FIREBASE_STORAGE_REST_TEST_ROOT_PATH'];
  test('env', () {
    print('TEKARTIK_FIREBASE_STORAGE_REST_TEST_ROOT_PATH: $testRootPath');
  });
  if (context != null) {
    if (shouldSkipEnvTestOnGithub()) {
      test('Skip env test on github', () {
        print('githubActionsPrefix: $githubActionsPrefix');
        print(
          'Env test only run by the dedicated env test workflow '
          '(ubuntu/stable)',
        );
      });
      return;
    }
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
          storageService: firebaseStorageServiceRest,
          options: context.options,
          storageOptions: TestStorageOptions(
            bucket: context.options!.storageBucket,
          ),
        );
      });
    });
  }
}
