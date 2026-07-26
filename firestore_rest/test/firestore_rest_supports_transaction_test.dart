import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase_rest/src/firebase_rest_identity.dart';
import 'package:test/test.dart';

Future<void> main() async {
  group('supportsTransaction', () {
    test('no auth', () async {
      var app = firebaseRest.initializeApp(
        options: AppOptionsRest()..projectId = 'dummy',
        name: 'supports_transaction_no_auth',
      );
      var firestore = firestoreServiceRest.firestore(app);
      expect(firestore.supportsTransaction, isFalse);
      await app.delete();
    });
    test('admin credentials', () async {
      var app = firebaseRest.initializeApp(
        options: AppOptionsRest(
          identifyServiceAccount: FirebaseRestIdentifyServiceAccountImpl(),
        )..projectId = 'dummy',
        name: 'supports_transaction_admin',
      );
      var firestore = firestoreServiceRest.firestore(app);
      expect(firestore.supportsTransaction, isTrue);
      await app.delete();
    });
    test('built in provider', () async {
      var app = firebaseRest.initializeApp(
        options: AppOptionsRest()..projectId = 'dummy',
        name: 'supports_transaction_built_in',
      );
      var authService = FirebaseAuthServiceRest(
        providers: () => [MockBuiltInAuthProviderRest()],
      );
      var auth = authService.auth(app);
      var firestore = firestoreServiceRest.firestore(app);
      // Not signed in yet
      expect(firestore.supportsTransaction, isFalse);
      await auth.signInAnonymously();
      expect(firestore.supportsTransaction, isFalse);
      await auth.signOut();
      expect(firestore.supportsTransaction, isFalse);
      await app.delete();
    });
  });
}
