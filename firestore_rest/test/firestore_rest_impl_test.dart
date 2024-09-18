// ignore_for_file: avoid_print

import 'package:http/http.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1.dart' as api;
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/import.dart';
import 'package:test/test.dart';

import 'no_auth_firestore.dart';
import 'test_setup.dart';

Future main() async {
  final context = await firestoreRestSetup();
  AppOptions? accessTokenAppOptions;
  if (context != null) {
    accessTokenAppOptions = getAppOptionsFromAccessToken(
        Client(), context.accessToken!.data,
        projectId: context.options!.projectId!, scopes: firebaseBaseScopes);
  }
  //print(context);
  group('rest', () {
    test('basic_googleapis', () async {
      var firestoreApi = api.FirestoreApi(context!.authClient!);

      // curl "https://firestore.googleapis.com/v1beta1/projects/tekartik-free-dev/databases/(default)/documents/tests/data-types"
      // curl "https://firestore.googleapis.com/projects/tekartik-free-dev/databases/(default)/documents/tests/data-types"
      // ignore: unused_local_variable
      var data = await firestoreApi.projects.databases.documents.get(
          'projects/tekartik-free-dev/databases/(default)/documents/tests/data-types');
      print(jsonPretty(data.toJson()));
    });

    test('access_token', () async {
      var app = firebaseRest.initializeApp(
          options: accessTokenAppOptions, name: 'access_token');
      var firestore = firestoreServiceRest.firestore(app);
      var snapshot = await firestore.doc('validate_user_access/_dummy').get();
      expect(snapshot.exists, isFalse);
    });
  }, skip: context == null);

  test('toRestValue', () {
    var firestore =
        noAuthFirestoreRest(projectId: 'dummy') as FirestoreRestImpl;
    expect(toRestValue(firestore, true).booleanValue, true);
    expect(toRestValue(firestore, FieldValue.serverTimestamp).timestampValue,
        isNotNull);
    try {
      toRestValue(firestore, FieldValue.delete);
      fail('should fail');
    } catch (e) {
      expect(e, isNot(const TypeMatcher<TestFailure>()));
    }
  });

  tearDownAll(() {
    context?.authClient?.close();
  });
}
