import 'package:googleapis/identitytoolkit/v3.dart' as identitytoolkit_v3;
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart';

/// Anonymous user credential implementation for REST API.
class UserCredentialAnonymousRestImpl extends UserCredentialRestImpl {
  /// Signup new user response.
  final identitytoolkit_v3.SignupNewUserResponse signUpResponse;

  /// Anonymous user credential implementation for REST API.
  UserCredentialAnonymousRestImpl(
    this.signUpResponse,
    super.credential,
    super.user,
  );

  @override
  String toString() => '$user $credential';

  @override
  String get idToken => signUpResponse.idToken!;
}
