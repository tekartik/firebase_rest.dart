// ignore_for_file: avoid_print

@TestOn('vm')
library;

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';

import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

Future main() async {
  var firebase = firebaseRest;
  var firebaseAuthServiceRest = FirebaseAuthServiceRest(
    persistence: FirebaseRestAuthPersistenceMemory(),
    providers: () => [MockBuiltInAuthProviderRest()],
  );
  var options = FirebaseAppOptions(projectId: 'test');

  group('basic', () {
    late FirebaseApp app;
    late FirebaseAuthRest auth;
    setUpAll(() async {
      app = firebase.initializeApp(options: options);
      auth = firebaseAuthServiceRest.auth(app);
    });
    tearDownAll(() async {
      await app.delete();
    });
    test('anonymous and sign out', () async {
      var user = await auth.signInAnonymously();
      print('user: $user');
      expect(auth.currentUser!.isAnonymous, isTrue);
      expect((await auth.onCurrentUser.first)!.isAnonymous, isTrue);
      await auth.signOut();
      expect(auth.currentUser, isNull);
      expect((await auth.onCurrentUser.first), isNull);
    });
    test('anonymous and restore', () async {
      auth.onCurrentUser.listen((event) {
        print('onCurrentUser: $event');
      });
      await auth.signInAnonymously();
      var userId = auth.currentUser!.uid;
      await app.delete();
      app = firebase.initializeApp(options: options);
      auth = firebaseAuthServiceRest.auth(app);
      expect(auth.currentUser, isNull); // not ready yet
      var fbUser = (await auth.onCurrentUser.first);
      print('fbUser: $fbUser');
      expect(fbUser?.uid, userId);
      await auth.signOut();
      expect(auth.currentUser, isNull);
      expect((await auth.onCurrentUser.first), isNull);
    });
  });
}
