@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' hide Context;
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  test('setup', () async {
    var serviceAccountJsonPath = join('test', 'local.service_account.json');
    if (File(serviceAccountJsonPath).existsSync()) {
      var context = await firebaseRestSetup(
        serviceAccountJsonPath: serviceAccountJsonPath,
      );
      expect(context!.authClient, isNotNull);
    }
  });
}
