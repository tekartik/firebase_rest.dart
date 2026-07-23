@TestOn('vm')
library;

import 'package:path/path.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/google_auth_rest_io.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleAuthProviderRestIoImpl credentials persistence', () {
    test('defaults to no persistence', () {
      var provider = GoogleAuthProviderRestIoImpl(GoogleAuthOptions());
      expect(provider.credentialsPersistence, isNull);
      expect(provider.credentialsPersistenceKey, 'google_auth_credentials');
    });

    test('derived from credentialPath', () {
      var credentialPath = join(
        'example',
        'local.config_io.user.credentials.yaml',
      );
      var provider = GoogleAuthProviderRestIoImpl(
        GoogleAuthOptions(),
        credentialPath: credentialPath,
      );
      var persistence =
          provider.credentialsPersistence as TekartikFirebasePersistenceFile;
      expect(persistence.directoryPath, 'example');
      expect(
        provider.credentialsPersistenceKey,
        'local.config_io.user.credentials.yaml',
      );
    });

    test('explicit persistence takes precedence over credentialPath', () {
      var explicitPersistence = TekartikFirebasePersistenceMemory();
      var provider = GoogleAuthProviderRestIoImpl(
        GoogleAuthOptions(),
        credentialPath: join('example', 'unused.yaml'),
        credentialsPersistence: explicitPersistence,
        credentialsPersistenceKey: 'my_key',
      );
      expect(provider.credentialsPersistence, same(explicitPersistence));
      expect(provider.credentialsPersistenceKey, 'my_key');
    });
  });
}
