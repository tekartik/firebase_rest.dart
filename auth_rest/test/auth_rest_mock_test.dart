// ignore_for_file: avoid_print

@TestOn('vm')
library;

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';

import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

Future main() async {
  var firebase = firebaseRest;
  var firebaseAuthServiceRest = FirebaseAuthServiceRest(
    persistence: FirebaseRestAuthPersistenceMemory(),
    providers: () => [MockBuiltInAuthProviderRest()],
  );
  var options = FirebaseAppOptions(projectId: 'test');
  group('auth_rest', () {
    test('factory', () {
      expect(firebaseAuthServiceRest.supportsListUsers, isFalse);
      expect(firebaseAuthServiceRest.supportsCurrentUser, isTrue);
    });

    runAuthTests(
      firebase: firebase,
      authService: firebaseAuthServiceRest,
      options: options,
    );
    group('access_token', () {
      runAuthTests(
        firebase: firebase,
        authService: firebaseAuthServiceRest,
        name: 'access_token',
        options: options,
      );
    });

    group('auth', () {
      late App app;
      // ignore: unused_local_variable
      late FirebaseAuthRest auth;
      var options = FirebaseAppOptions(projectId: 'auth_test');
      setUpAll(() async {
        app = firebase.initializeApp(
          name: 'auth',
          options: options,
        ); //, options: context?.options);
        auth = firebaseAuthServiceRest.auth(app);
      });

      tearDownAll(() {
        return app.delete();
      });
    });
  });
}
