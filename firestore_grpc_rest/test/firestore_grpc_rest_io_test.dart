@TestOn('vm')
library;

// ignore_for_file: avoid_print

import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore_grpc_rest/firestore_grpc_rest.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  // ignore: deprecated_member_use
  debugFirestoreRest = devWarning(true);
  skipConcurrentTransactionTests = true;
  var context = await firestoreRestSetup();
  if (context == null) {
    test('no local service account', () {});
    return;
  }
  var testContext = FirestoreTestContext();

  var firestore = firestoreServiceRest.firestore(context.app);
  var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);
  group('grpc_rest_io', () {
    group('DocumentReference', () {
      test('onGrpcSnapshot', () async {
        var ref = firestore.doc(
          url.join(testsRefPath, 'document_reference_grpc_rest'),
        );
        try {
          await ref.delete();
        } catch (_) {}

        var completer0 = Completer<void>();
        var completer1 = Completer<void>();
        var completer2 = Completer<void>();
        var completerFinal = Completer<void>();
        var snapshot = await ref.onGrpcSnapshot().first;
        expect(snapshot.exists, isFalse);

        var subscription = ref.onGrpcSnapshot().listen((snapshot) {
          print(snapshot);
          var map = snapshot.dataOrNull;
          if (!completer0.isCompleted) {
            if (map == null) {
              completer0.safeComplete();
            }
            return;
          }
          if (map?['test'] == 1) {
            completer1.safeComplete();
          }
          if (map?['test'] == 2) {
            completer2.safeComplete();
          }
          if (completer2.isCompleted && map == null) {
            completerFinal.safeComplete();
          }
        });
        await completer0.future;
        await ref.set({'test': 1});
        await completer1.future;
        await ref.set({'test': 2});
        await completer2.future;
        await ref.delete();
        await completerFinal.future;
        await subscription.cancel();
      });
    });
  });
}
