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

  /// Restore user credential.
  @override
  Future<UserCredentialRest?> restore() async {
    if (persistence != null) {
      var credentials = await persistence!.get(projectId);
      if (credentials != null) {
        var providerId = credentials.providerId;
        if (providerId == this.providerId) {
          var user = await _initWithAccessCredentials(
            credentials as FirebaseRestAuthPersistenceAccessCredentialsMap,
          );
          return user;
        }
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
    var client = ApiKeyClient(apiKey: authRest.app.options.apiKey!);
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

    await setCurrentUserCredential(userCredential);
    return userCredential;
  }

  /// Reload the current rest user
  Future<FirebaseUserRest> reloadCurrentUser() async {
    await authReady;
    var appRest = authRest.impl.appRest;
    var client = ApiKeyClient(apiKey: appRest.options.apiKey!);
    var apiV3 = identitytoolkit_v3.IdentityToolkitApi(client);
    var response = await apiV3.relyingparty.getAccountInfo(
      identitytoolkit_v3.IdentitytoolkitRelyingpartyGetAccountInfoRequest()
        ..localId = [currentUserCredential!.user.uid],
    );
    if (response.users?.isNotEmpty ?? false) {
      var restUserInfo = response.users!.first;
      var userRest = FirebaseUserRest(
        emailVerified: restUserInfo.emailVerified ?? false,
        client: client,
        email: restUserInfo.email,
        isAnonymous: restUserInfo.email == null,
        uid: restUserInfo.localId!,
        provider: this,
      );
      return userRest;
    }
    throw StateError('no account found');
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await authReady;
    var appRest = authRest.impl.appRest;
    var client = ApiKeyClient(apiKey: appRest.options.apiKey!);
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
        email: response.email,
        emailVerified: false,
        provider: this,
        uid: response.localId!,
        isAnonymous: false,
      ),
    );
    // ignore: deprecated_member_use

    await setCurrentUserCredential(userCredential);
    return userCredential;
  }

  /// Initialize with access credentials
  Future<UserCredentialRest?> _initWithAccessCredentials(
    FirebaseRestAuthPersistenceAccessCredentialsMap credentials,
  ) async {
    // var appRest = authRest.impl.appRest;
    // var client = ApiKeyClient(apiKey: appRest.options.apiKey!);

    // devPrint('signInWithPassword response: ${jsonEncode(response.toJson())}');
    var userCredential = credentials.getCredential(this);
    return userCredential;
  }

  /// Provider ID.
  @override
  String get providerId => 'built_in';
}
