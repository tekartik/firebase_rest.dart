import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart';

import '../auth_rest.dart';
import 'identitytoolkit/v3.dart' as identitytoolkit_v3;

/// User credential email password implementation
class UserCredentialEmailPasswordRestImpl extends UserCredentialRestImpl {
  /// The sign in response
  final identitytoolkit_v3.VerifyPasswordResponse signInResponse;

  /// Create user credential, keeping the refresh token and the expiration of
  /// the response so the id token can be renewed.
  UserCredentialEmailPasswordRestImpl(
    this.signInResponse,
    super.credential,
    super.user,
  ) : super(
        tokens: RestAuthTokens.fromSignIn(
          idToken: signInResponse.idToken!,
          refreshToken: signInResponse.refreshToken,
          expiresIn: signInResponse.expiresIn,
        ),
      );

  @override
  String toString() => '$user $credential';

  @override
  String get idToken => tokens!.idToken;
}

/// User credential rest implementation
abstract class UserCredentialRestImpl implements UserCredentialRest {
  @override
  final AuthCredentialRestImpl credential;

  @override
  final FirebaseUserRest user;

  /// The tokens when the id token can be renewed (identity toolkit sign in),
  /// null otherwise (google, mock).
  @override
  RestAuthTokens? tokens;

  /// Create user credential
  UserCredentialRestImpl(this.credential, this.user, {this.tokens});

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
