import 'dart:async';

import 'package:googleapis/identitytoolkit/v1.dart' as identitytoolkit_v1;
import 'package:googleapis/identitytoolkit/v3.dart' as identitytoolkit_v3;
import 'package:path/path.dart';
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
    var client = _newApiKeyClient();
    var apiV3 = _apiV3(client);
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
    var client = _newApiKeyClient();
    var apiV3 = _apiV3(client);
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

  ApiKeyClient _newApiKeyClient() {
    var appRest = authRest.impl.appRest;
    return ApiKeyClient(apiKey: appRest.options.apiKey!);
  }

  bool get _useEmulator => authRest.impl.useEmulator;

  String get _projectId => authRest.app.projectId;

  /// Get user by email
  Future<UserRecord?> getUserByEmail(String email) async {
    await authReady;
    var client = _newApiKeyClient();

    try {
      if (_useEmulator) {
        var apiV1 = _apiV1(client);
        late identitytoolkit_v1.GoogleCloudIdentitytoolkitV1GetAccountInfoResponse
        response;
        try {
          response = await apiV1.accounts.lookup(
            identitytoolkit_v1.GoogleCloudIdentitytoolkitV1GetAccountInfoRequest(
              email: [email],
              targetProjectId: _projectId,
              // Registering as admin
              delegatedProjectNumber: _projectId,
            ),
          );
        } on identitytoolkit_v1.DetailedApiRequestError catch (e) {
          if (e.status == 404) {
            return null;
          }
          rethrow;
        }
        var users =
            (response.users ??
            <identitytoolkit_v1.GoogleCloudIdentitytoolkitV1UserInfo>[]);
        return users.map((restUserInfo) {
          return UserRecordRest(
              disabled: false,
              emailVerified: false,
              isAnonymous: false,
            )
            ..displayName = restUserInfo.displayName
            ..email = restUserInfo.email
            ..uid = restUserInfo.localId!;
        }).firstOrNull;
      } else {
        var apiV3 = identitytoolkit_v3.IdentityToolkitApi(client);
        var response = await apiV3.relyingparty.getAccountInfo(
          identitytoolkit_v3.IdentitytoolkitRelyingpartyGetAccountInfoRequest()
            ..email = [email],
        );
        if (response.users?.isNotEmpty ?? false) {
          return toUserRecord(response.users!.first);
        }
      }

      return null;
    } finally {
      client.close();
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await authReady;
    var client = _newApiKeyClient();
    try {
      identitytoolkit_v3.VerifyPasswordResponse response;
      if (_useEmulator) {
        var apiV1 = _apiV1(client);
        var v1Response = await apiV1.accounts.signInWithPassword(
          identitytoolkit_v1.GoogleCloudIdentitytoolkitV1SignInWithPasswordRequest(
            email: email,
            password: password,
            returnSecureToken: true,
          ),
        );
        response = identitytoolkit_v3.VerifyPasswordResponse(
          email: v1Response.email,
          idToken: v1Response.idToken,
          localId: v1Response.localId,
          refreshToken: v1Response.refreshToken,
          expiresIn: v1Response.expiresIn,
        );
      } else {
        var apiV3 = _apiV3(client);

        response = await apiV3.relyingparty.verifyPassword(
          identitytoolkit_v3.IdentitytoolkitRelyingpartyVerifyPasswordRequest()
            ..email = email
            ..password = password
            ..returnSecureToken = true,
        );
      }

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

      await setCurrentUserCredential(userCredential);
      return userCredential;
    } finally {
      client.close();
    }
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

  identitytoolkit_v1.IdentityToolkitApi _apiV1(ApiKeyClient client) {
    var rootUrl = authRest.impl.rootUrl!;
    var apiV1 = identitytoolkit_v1.IdentityToolkitApi(
      client,
      rootUrl: url.join(rootUrl, 'identitytoolkit.googleapis.com/'),
    );
    return apiV1;
  }

  identitytoolkit_v3.IdentityToolkitApi _apiV3(ApiKeyClient client) {
    var rootUrl = authRest.impl.rootUrl;
    if (rootUrl == null) {
      return identitytoolkit_v3.IdentityToolkitApi(client);
    } else {
      var apiV3 = identitytoolkit_v3.IdentityToolkitApi(
        client,
        rootUrl: rootUrl,
      );
      return apiV3;
    }
  }

  /// Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await authReady;
    var client = _newApiKeyClient();

    try {
      identitytoolkit_v3.SignupNewUserResponse response;
      if (authRest.impl.useEmulator) {
        var apiV1 = _apiV1(client);

        var v1Response = await apiV1.accounts.signUp(
          identitytoolkit_v1.GoogleCloudIdentitytoolkitV1SignUpRequest(
            email: email,
            password: password,
          ),
        );
        response = identitytoolkit_v3.SignupNewUserResponse(
          email: v1Response.email,
          idToken: v1Response.idToken,
          localId: v1Response.localId,
          refreshToken: v1Response.refreshToken,
          expiresIn: v1Response.expiresIn,
        );
      } else {
        var apiV3 = _apiV3(client);

        response = await apiV3.relyingparty.signupNewUser(
          identitytoolkit_v3.IdentitytoolkitRelyingpartySignupNewUserRequest()
            ..email = email
            ..password = password,
          //..returnSecureToken = true,
        );
      }

      var userCredential = UserCredentialEmailPasswordRestImpl(
        identitytoolkit_v3.VerifyPasswordResponse(
          email: response.email,
          idToken: response.idToken,
          localId: response.localId,
          refreshToken: response.refreshToken,
          expiresIn: response.expiresIn,
        ),
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

      await setCurrentUserCredential(userCredential);
      return userCredential;
    } finally {
      client.close();
    }
  }
}
