import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:test/test.dart';

import 'src/auth_rest_persistence_test_runner.dart';

void main() {
  group('memory', () {
    runFirebaseRestAuthPersistenceTests(
      () => FirebaseRestAuthPersistenceMemory(),
    );
  });

  group('onPersistence (generic memory)', () {
    // Demonstrates that FirebaseRestAuthPersistence can be built on top of
    // any TekartikFirebasePersistence implementation.
    runFirebaseRestAuthPersistenceTests(
      () => FirebaseRestAuthPersistenceOnPersistence(
        TekartikFirebasePersistenceMemory(),
      ),
    );
  });
}
