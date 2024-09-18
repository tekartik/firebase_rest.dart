// ignore_for_file: avoid_print

@TestOn('vm')
library;

import 'package:process_run/shell.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_rest/test/setup.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  // debugFirestoreRest = devWarning(true);
  var context = await firestoreRestSetup(useEnv: true);
  skipConcurrentTransactionTests = true;
  var testRootCollectionPath =
      shellEnvironment['TEKARTIK_FIRESTORE_REST_TEST_ROOT_COLLECTION_PATH'];
  test('env', () {
    print(
        'TEKARTIK_FIRESTORE_REST_TEST_ROOT_COLLECTION_PATH: $testRootCollectionPath');
  });
  if (context == null || testRootCollectionPath == null) {
    test('no env setup available', () {});
  } else {
    if (runningOnGithub && !isGithubActionsUbuntuAndDartStable()) {
      test('Skip on github for other than ubuntu and dart stable', () {
        print('githubActionsPrefix: $githubActionsPrefix');
      });
      return;
    }
    group('rest_io', () {
      test('setup', () {
        print('Using firebase project: ${context.options!.projectId}');
      });
      var firebase = firebaseRest;
      runFirestoreTests(
          firebase: firebase,
          firestoreService: firestoreServiceRest,
          options: context.options,
          testContext:
              FirestoreTestContext(rootCollectionPath: testRootCollectionPath));
    });
  }
}
