@TestOn('vm')
library;

import 'package:idb_shim/sdb/sdb.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/google_auth_rest_io.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleAuthProviderRestIoImpl credentials persistence', () {
    test('defaults to no persistence', () {
      var provider = GoogleAuthProviderRestIoImpl(GoogleAuthOptions());
      expect(provider.credentialsPersistence, isNull);
      expect(provider.credentialsKey, 'google_auth_credentials');
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
      expect(provider.credentialsKey, 'local.config_io.user.credentials.yaml');
    });

    test('explicit persistence takes precedence over credentialPath', () {
      var explicitPersistence = TekartikFirebasePersistenceMemory();
      var provider = GoogleAuthProviderRestIoImpl(
        GoogleAuthOptions(),
        credentialPath: join('example', 'unused.yaml'),
        credentialsPersistence: explicitPersistence,
        credentialsKey: 'my_key',
      );
      expect(provider.credentialsPersistence, same(explicitPersistence));
      expect(provider.credentialsKey, 'my_key');
    });

    test('sdb store', () async {
      var store = TekartikFirebasePersistenceSdb(
        sdbFactory: sdbFactoryMemory,
        dbName: 'google_auth_rest_io_test',
      );
      var provider = GoogleAuthProviderRestIoImpl(
        GoogleAuthOptions(),
        credentialsPersistence: store,
        credentialsKey: 'my_key',
      );
      expect(provider.credentialsPersistence, same(store));
      expect(provider.credentialsKey, 'my_key');

      // The provider only ever needs the KvStore surface.
      var kvStore = provider.credentialsPersistence!;
      await kvStore.setString('my_key', 'my_value');
      expect(await kvStore.getString('my_key'), 'my_value');
      await kvStore.remove('my_key');
      expect(await kvStore.getString('my_key'), isNull);
      await store.close();
    });

    test('credentialsPersistenceKey is still accepted', () {
      var provider = GoogleAuthProviderRestIoImpl(
        GoogleAuthOptions(),
        // ignore: deprecated_member_use_from_same_package
        credentialsPersistenceKey: 'my_key',
      );
      expect(provider.credentialsKey, 'my_key');
      // ignore: deprecated_member_use_from_same_package
      expect(provider.credentialsPersistenceKey, 'my_key');
    });
  });
}
