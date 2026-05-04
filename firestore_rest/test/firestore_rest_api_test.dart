// ignore_for_file: avoid_print

import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  test('supports', () {
    expect(firestoreServiceRest.supportsBlobs, isTrue);
  });
  final context = await firestoreRestSetup();
  print(context);
  group('rest', () {
    test('basic', () {});
  }, skip: context == null);
}
