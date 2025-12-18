import 'dart:async';

import 'package:googleapis/identitytoolkit/v3.dart' as identitytoolkit_v3;
import 'package:tekartik_firebase_auth_rest/auth_rest_io.dart';

import 'anonymous_auth_rest.dart';
import 'auth_rest.dart';
import 'auth_rest_persistence.dart';
import 'auth_rest_provider.dart';
import 'email_password_auth_rest.dart';

/// One instance
class BuiltInAuthProviderRest extends AuthProviderRestBase {
  /// Create built-in auth provider
  BuiltInAuthProviderRest();

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

  /// Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    /// wait for restore if needed
    await authReady;
    // 3. Prepare the request
    final request =
        identitytoolkit_v3.IdentitytoolkitRelyingpartySignupNewUserRequest();
    var client = ApiKeyClientClient(apiKey: authRest.app.options.apiKey!);
    var apiV3 = identitytoolkit_v3.IdentityToolkitApi(client);
    // 4. Call the signUp method (Anonymous sign-in is a signUp with no email/password)
    // The '$fields' or custom query params can be used to pass the key
    final response = await apiV3.relyingparty.signupNewUser(request);

    // devPrint('signInWithPassword response: ${jsonEncode(response.toJson())}');
    var userCredential = UserCredentialAnonymousRestImpl(
      response,
      AuthCredentialRestImpl(),
      UserRest(
        client: client,
        emailVerified: false,
        provider: this,
        uid: response.localId!,
        isAnonymous: true,
      ),
    );
    // Here we set the global client to be used for requests
    // ignore: deprecated_member_use
    currentAuthClient = LoggedInClient(userCredential: userCredential);
    await setCurrentUserCredential(userCredential);
    return userCredential;
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await authReady;
    var appRest = authRest.impl.appRest;
    var client = ApiKeyClientClient(apiKey: appRest.options.apiKey!);
    var apiV3 = identitytoolkit_v3.IdentityToolkitApi(client);
    var response = await apiV3.relyingparty.verifyPassword(
      identitytoolkit_v3.IdentitytoolkitRelyingpartyVerifyPasswordRequest()
        ..email = email
        ..password = password
        ..returnSecureToken = true,
    );

    // devPrint('signInWithPassword response: ${jsonEncode(response.toJson())}');
    var userCredential = UserCredentialEmailPasswordRestImpl(
      response,
      AuthCredentialRestImpl(),
      UserRest(
        client: client,
        emailVerified: false,
        provider: this,
        uid: response.localId!,
        isAnonymous: false,
      ),
    );
    // ignore: deprecated_member_use
    appRest.client = LoggedInClient(userCredential: userCredential);
    await setCurrentUserCredential(userCredential);
    return userCredential;
  }

  @override
  Future<void> saveUser(UserCredentialRest? user) async {
    if (persistence != null) {
      if (user != null) {
        var credentials =
            FirebaseRestAuthPersistenceAccessCredentials.fromUserCredential(
              user,
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
    return null;
  }

  @override
  String get providerId => 'built_in';
}
