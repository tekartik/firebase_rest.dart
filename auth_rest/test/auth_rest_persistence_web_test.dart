@TestOn('browser')
library;

import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:test/test.dart';

import 'src/auth_rest_persistence_test_runner.dart';

void main() {
  group('web (local storage)', () {
    runFirebaseRestAuthPersistenceTests(() => FirebaseRestAuthPersistenceWeb());
  });
}
