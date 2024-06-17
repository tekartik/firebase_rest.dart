@TestOn('vm')
library;

import 'package:process_run/shell.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  // debugFirestoreRest = devWarning(true);
  var context = await setup(useEnv: true);
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
