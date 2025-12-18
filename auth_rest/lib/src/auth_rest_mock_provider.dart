import 'dart:async';

import 'package:tekartik_firebase_auth_rest/auth_rest_io.dart';

import 'auth_rest.dart';
import 'auth_rest_persistence.dart';

/// User credential google rest implementation
class _UserCredentialRestMockImpl extends UserCredentialRestImpl {
  /// Create user credential google
  _UserCredentialRestMockImpl(
    super.credential,
    super.user, {
    required this.idToken,
  });

  @override
  String toString() => '$user $credential';

  @override
  final String idToken;
}

/// Mock built in auth provider rest implementation
class MockBuiltInAuthProviderRest extends BuiltInAuthProviderRest {
  @override
  String get providerId => 'mock_built_in';
  @override
  Future<UserCredentialRest?> restore() async {
    if (persistence != null) {
      var credentials = await persistence!.get(projectId);
      if (credentials != null) {
        var user = await _initWithAccessCredentials(credentials);
        return user;
      }
    }
    return null;
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Just create a mock user
    var userCredential = _UserCredentialRestMockImpl(
      idToken: 'mock_id_token',
      AuthCredentialRestImpl(),
      UserRest(
        client: authRest.impl.appRest.client,
        emailVerified: false,
        provider: this,
        uid: 'mock_anonymous_uid',
        isAnonymous: false,
      ),
    );

    // save()
    return userCredential;
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    // Just create a mock user
    var userCredential = _UserCredentialRestMockImpl(
      idToken: 'mock_id_token',
      AuthCredentialRestImpl(),
      UserRest(
        client: authRest.impl.appRest.client,
        emailVerified: false,
        provider: this,

        uid: 'mock_anonymous_uid',
        isAnonymous: true,
      ),
    );

    await setCurrentUserCredential(userCredential);
    // save()
    return userCredential;
  }

  @override
  Future<void> saveUser(UserCredentialRest? user) async {
    if (persistence != null) {
      if (user != null) {
        var credentials =
            FirebaseRestAuthPersistenceAccessCredentials.fromUserCredential(
              user,
              //      accessToken: user.accessToken!,
              //     refreshToken: user.refreshToken!,
              //    expiry: user.accessTokenExpiry!,
            );
        await persistence!.set(projectId, credentials);
      } else {
        await persistence!.remove(projectId);
      }
    }
  }

  Future<UserCredentialRest?> _initWithAccessCredentials(
    FirebaseRestAuthPersistenceAccessCredentials credentials,
  ) async {
    return UserCredentialRest(
      credential: AuthCredentialRestImpl(),
      user: FirebaseUserRest(
        emailVerified: false,
        isAnonymous: true,
        uid: credentials.uid,
        provider: this,
      ),
      idToken: 'mock_id_token',
    );
  }
}
