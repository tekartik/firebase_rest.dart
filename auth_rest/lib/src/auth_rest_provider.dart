import 'package:http/http.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest_io.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest_persistence.dart';

import 'auth_rest.dart';
import 'auth_service_rest.dart';
import 'email_password_auth_rest.dart';

/// Extra rest information
abstract class AuthProviderRest implements AuthProvider {
  /// Sign in
  Future<AuthSignInResult> signIn();

  /// On current user
  Stream<FirebaseUserRest?> get onCurrentUser;

  /// Get id token
  Future<String> getIdToken({bool? forceRefresh});

  /// Sign out
  Future<void> signOut();

  /// Current auth client
  Client? get currentAuthClient;
}

/// Auth provider rest mixin
mixin AuthProviderRestMixin implements AuthProviderRest {
  /// Auth ready completer.
  final _authReadyCompleter = Completer<bool>();

  /// Current user credential
  UserCredentialRest? currentUserCredential;

  /// Current user controller
  /// Created in constructor on first listen to onCurrentUser
  late final StreamController<UserRest?> currentUserController =
      StreamController.broadcast(
        onListen: () async {
          await setCurrentUserCredential(await restore(), noSave: true);
          _authReadyCompleter.safeComplete(true);
        },
        sync: true,
      );

  /// Auth ready future
  Future<bool> get authReady => _authReadyCompleter.future;
  @override
  Client? currentAuthClient;

  /// Project ID helper
  String get projectId => authRest.app.options.projectId!;

  /// Persistence helper
  FirebaseRestAuthPersistence? get persistence =>
      authRest.serviceRest.prv.persistence;

  /// Auth rest helper
  late final FirebaseAuthRest authRest;

  /// Initialize with auth rest
  void init(FirebaseAuthRest authRest) {
    this.authRest = authRest;
  }

  @override
  Future<void> signOut() async {
    await setCurrentUserCredential(null);
  }

  /// Set current user credential
  Future<void> setCurrentUserCredential(
    UserCredentialRest? userCredential, {
    bool noSave = false,
  }) async {
    if (userCredential != null) {
      currentAuthClient = LoggedInClient(
        userCredential: userCredential,
        refreshToken: ({bool force = false}) =>
            refreshIdToken(credential: userCredential, force: force),
      );
    } else {
      currentAuthClient = null;
    }
    currentUserCredential = userCredential;
    var userRest = userCredential?.user as UserRest?;
    var ctlr = currentUserController;
    // devPrint('currentUserController $ctlr');
    ctlr.add(userRest);
    if (!noSave) {
      /// Asynchronously save user
      await saveUser(userCredential);
    }
  }

  /// Restore user credential
  Future<UserCredentialRest?> restore() async {
    return null;
  }

  /// Renews id tokens through the secure token api, null when the app has no
  /// api key (nothing to renew with).
  RestAuthTokenRefresher? get tokenRefresher {
    var impl = authRest.impl;
    var apiKey = impl.appRest.options.apiKey;
    if (apiKey == null) {
      return null;
    }
    return RestAuthTokenRefresher(apiKey: apiKey, rootUrl: impl.rootUrl);
  }

  Future<void>? _refreshing;

  /// Renew the id token of [credential] (the current user by default) when it
  /// is expiring, or when [force].
  ///
  /// A no-op when the credential cannot be renewed (no refresh token). One
  /// renewal at a time, callers share it. The new tokens are persisted when
  /// [credential] is the current user. A refused renewal
  /// ([RestAuthTokenRefreshException.isSessionExpired]) signs the current user
  /// out and rethrows; anything else (network) just rethrows.
  Future<void> refreshIdToken({
    UserCredentialRest? credential,
    bool force = false,
  }) {
    credential ??= currentUserCredential;
    var tokens = credential?.tokens;
    if (credential == null || tokens == null || !tokens.canRefresh) {
      return Future.value();
    }
    if (!force && !tokens.isExpiring()) {
      return Future.value();
    }
    return _refreshing ??= _refreshTokens(
      credential,
      tokens,
    ).whenComplete(() => _refreshing = null);
  }

  Future<void> _refreshTokens(
    UserCredentialRest credential,
    RestAuthTokens tokens,
  ) async {
    var refresher = tokenRefresher;
    if (refresher == null) {
      return;
    }
    try {
      tokens.update(await refresher.refresh(tokens.refreshToken!));
    } on RestAuthTokenRefreshException catch (e) {
      if (e.isSessionExpired && identical(credential, currentUserCredential)) {
        await setCurrentUserCredential(null);
      }
      rethrow;
    }
    if (identical(credential, currentUserCredential)) {
      await saveUser(credential);
    }
  }

  /// The id token of the current user, renewed first when expiring or when
  /// [forceRefresh].
  @override
  Future<String> getIdToken({bool? forceRefresh}) async {
    var credential = currentUserCredential;
    if (credential == null) {
      throw StateError('getIdToken: no signed in user');
    }
    await refreshIdToken(credential: credential, force: forceRefresh == true);
    return credential.idToken;
  }

  /// Save user credential.
  Future<void> saveUser(UserCredentialRest? user) async {
    if (persistence != null) {
      if (user != null) {
        var credentials =
            FirebaseRestAuthPersistenceAccessCredentialsUserCredential(
              providerId: providerId,
              user: user,
            );
        await persistence!.set(projectId, credentials);
      } else {
        await persistence!.remove(projectId);
      }
    }
  }

  @override
  Stream<FirebaseUserRest?> get onCurrentUser async* {
    var ctlr = currentUserController;
    yield* ctlr.stream;
  }
}

/// Private extension
extension AuthProviderRestPrv on AuthProvider {
  /// Mixin access
  AuthProviderRestMixin get mixin => this as AuthProviderRestMixin;
}

/// Base provider rest implementation
abstract class AuthProviderRestBase
    with AuthProviderRestMixin
    implements AuthProviderRest {
  /// Sign in.
  @override
  Future<AuthSignInResult> signIn() {
    // TODO: implement signIn
    throw UnimplementedError();
  }
}
