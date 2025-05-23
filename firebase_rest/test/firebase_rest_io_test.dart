@TestOn('vm')
library;

import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_rest/src/test/test_setup.dart'
    show firebaseRestSetup;
import 'package:tekartik_firebase_test/firebase_test.dart';
import 'package:test/test.dart';

Future main() async {
  var firebaseRest = await firebaseRestSetup();

  if (firebaseRest == null) {
    test('no setup available', () {});
  } else {
    group('rest', () {
      test('isLocal', () {
        expect(firebaseRest.isLocal, isFalse);
      });
      // there is no name on node
      runFirebaseTests(firebaseRest);

      test('authClient', () {
        if (firebaseRest is FirebaseAdminRest) {
          expect(
            (firebaseRest.credential.applicationDefault()
                    as FirebaseAdminCredentialRest)
                .authClient,
            isNotNull,
          );
        }
      });

      test('initialize sync and latest', () {
        FirebaseMixin.latestFirebaseInstanceOrNull = null;
        var firebase = firebaseRest;
        var app = firebase.initializeApp(
          options: AppOptions(projectId: 'test'),
        );
        expect(FirebaseMixin.latestFirebaseInstanceOrNull, app);
      });

      test('admin', () async {
        if (firebaseRest is FirebaseAdminRest) {
          expect(
            (await firebaseRest.credential
                    .applicationDefault()!
                    .getAccessToken())
                .data,
            isNotNull,
          );
        }
      });
    });
  }
}
