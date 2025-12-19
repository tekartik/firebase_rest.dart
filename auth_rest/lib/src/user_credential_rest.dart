import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart';

import '../auth_rest.dart';
import 'identitytoolkit/v3.dart' as identitytoolkit_v3;

/// User credential email password implementation
class UserCredentialEmailPasswordRestImpl extends UserCredentialRestImpl {
  /// The sign in response
  final identitytoolkit_v3.VerifyPasswordResponse signInResponse;

  /// Create user credential
  UserCredentialEmailPasswordRestImpl(
    this.signInResponse,
    super.credential,
    super.user,
  );

  @override
  String toString() => '$user $credential';

  @override
  String get idToken => signInResponse.idToken!;
}

/// User credential rest implementation
abstract class UserCredentialRestImpl implements UserCredentialRest {
  @override
  final AuthCredentialRestImpl credential;

  @override
  final FirebaseUserRest user;

  /// Create user credential
  UserCredentialRestImpl(this.credential, this.user);

  @override
  String toString() => '$user $credential';
}

/// User credential google rest implementation
class UserCredentialGoogleRestImpl extends UserCredentialRestImpl {
  /// Create user credential google
  UserCredentialGoogleRestImpl(
    super.credential,
    super.user, {
    required this.idToken,
  });

  @override
  String toString() => '$user $credential';

  @override
  final String idToken;
}

/// Auth credential implementation
class AuthCredentialImpl implements AuthCredential {
  @override
  final String providerId;

  /// Create auth credential
  AuthCredentialImpl({this.providerId = localProviderId});

  @override
  String toString() => 'AuthCredential($providerId)';
}
