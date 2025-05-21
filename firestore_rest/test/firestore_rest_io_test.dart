@TestOn('vm')
library;

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  // debugFirestoreRest = devWarning(true);
  skipConcurrentTransactionTests = true;
  var context = await firestoreRestSetup();
  group('rest_io', () {
    if (context != null) {
      var firebase = firebaseRest;
      runFirestoreTests(
        firebase: firebase,
        firestoreService: firestoreServiceRest,
        testContext: FirestoreTestContext()..allowedDelayInReadMs = 3000,
        options: context.options,
      );
    }
  }, skip: context == null);
}
