import 'package:tekartik_firebase_auth_rest/src/auth_rest_persistence.dart';
import 'package:test/test.dart';

FirebaseRestAuthPersistenceAccessCredentials _credentials({
  required String uid,
  required String providerId,
  String? email,
  String idToken = 'id-token',
  String? refreshToken,
  DateTime? expiresAt,
}) => FirebaseRestAuthPersistenceAccessCredentialsMap({
  'uid': uid,
  'providerId': providerId,
  'emailVerified': email != null,
  'isAnonymous': false,
  'email': email,
  'idToken': idToken,
  'refreshToken': ?refreshToken,
  'expiresAt': ?expiresAt?.toUtc().toIso8601String(),
});

/// Shared contract tests, reused across implementations.
void runFirebaseRestAuthPersistenceTests(
  FirebaseRestAuthPersistence Function() factory,
) {
  late FirebaseRestAuthPersistence persistence;
  setUp(() {
    persistence = factory();
  });
  tearDown(() async {
    await persistence.remove('project1');
    await persistence.remove('project2');
  });

  test('missing project', () async {
    expect(await persistence.get('project1'), isNull);
  });

  test('set/get/remove', () async {
    var credentials = _credentials(
      uid: 'uid1',
      providerId: 'password',
      email: 'test@example.com',
    );
    await persistence.set('project1', credentials);
    var read = await persistence.get('project1');
    expect(read, isNotNull);
    expect(read!.uid, 'uid1');
    expect(read.providerId, 'password');
    expect(read.email, 'test@example.com');
    expect(read.emailVerified, isTrue);
    expect(read.idToken, 'id-token');
    // Persisted before refresh tokens were kept.
    expect(read.refreshToken, isNull);
    expect(read.expiresAt, isNull);

    await persistence.remove('project1');
    expect(await persistence.get('project1'), isNull);
  });

  test('refresh token and expiration', () async {
    var expiresAt = DateTime(2026, 9, 15, 13, 1, 44);
    await persistence.set(
      'project1',
      _credentials(
        uid: 'uid1',
        providerId: 'password',
        refreshToken: 'refresh-token',
        expiresAt: expiresAt,
      ),
    );
    var read = await persistence.get('project1');
    expect(read!.refreshToken, 'refresh-token');
    expect(read.expiresAt, expiresAt);
    expect(read.toMap()['expiresAt'], expiresAt.toUtc().toIso8601String());
  });

  test('overwrite', () async {
    await persistence.set(
      'project1',
      _credentials(uid: 'uid1', providerId: 'password'),
    );
    await persistence.set(
      'project1',
      _credentials(uid: 'uid2', providerId: 'google'),
    );
    var read = await persistence.get('project1');
    expect(read!.uid, 'uid2');
    expect(read.providerId, 'google');
  });

  test('multiple projects', () async {
    await persistence.set(
      'project1',
      _credentials(uid: 'uid1', providerId: 'password'),
    );
    await persistence.set(
      'project2',
      _credentials(uid: 'uid2', providerId: 'google'),
    );
    expect((await persistence.get('project1'))!.uid, 'uid1');
    expect((await persistence.get('project2'))!.uid, 'uid2');
    await persistence.remove('project1');
    expect(await persistence.get('project1'), isNull);
    expect((await persistence.get('project2'))!.uid, 'uid2');
  });
}
