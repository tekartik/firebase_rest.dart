import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  final context = await firestoreRestSetup();
  print(context);
  group('rest', () {
    test('basic', () {});
  }, skip: context == null);
}
