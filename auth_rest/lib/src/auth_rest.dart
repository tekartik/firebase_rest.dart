import 'package:googleapis/identitytoolkit/v3.dart' as identitytoolkit_v3;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_auth_rest/src/identitytoolkit/v3.dart'
    hide UserInfo;
import 'package:tekartik_firebase_auth_rest/src/identitytoolkit/v3.dart' as api;
import 'package:tekartik_firebase_rest/firebase_rest.dart';

import 'email_password_auth_rest.dart';
import 'google_auth_rest.dart';
import 'import.dart';

/// Debug rest (to move to firebase rest)
//bool debugRest = false; // devWarning(true); // false
var debugFirebaseAuthRest = false; // devWarning(true);

void _log(Object? message) {
  print(message);
}

@Deprecated('Use AuthProviderRest')
abstract class AuthRestProvider implements AuthProvider {
  factory AuthRestProvider() {
    return AuthLocalProviderImpl();
  }
}

const localProviderId = '_local';

// ignore: deprecated_member_use_from_same_package
class AuthLocalProviderImpl implements AuthRestProvider {
  @override
  String get providerId => localProviderId;
}

/*
class AuthLocalSignInOptions implements AuthSignInOptions {
  final UserRecordRest _userRecordLocal;

  AuthLocalSignInOptions(this._userRecordLocal);
}

 */

class EmailPasswordAuthProviderRest implements AuthProviderRest {
  @override
  // TODO: implement currentAuthClient
  AuthClient get currentAuthClient => throw UnimplementedError();

  @override
  Future<String> getIdToken({bool? forceRefresh}) {
    // TODO: implement getIdToken
    throw UnimplementedError();
  }

  @override
  // TODO: implement onCurrentUser
  Stream<FirebaseUserRest?> get onCurrentUser => throw UnimplementedError();

  @override
  // TODO: implement providerId
  String get providerId => throw UnimplementedError();

  @override
  Future<AuthSignInResult> signIn() {
    // TODO: implement signIn
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    // TODO: implement signOut
    throw UnimplementedError();
  }
}

class ListUsersResultRest implements ListUsersResult {
  @override
  final String pageToken;

  @override
  final List<UserRecord> users;

  ListUsersResultRest({required this.pageToken, required this.users});
}

class AuthSignInResultImpl implements AuthSignInResult {
  @override
  final UserCredential credential;

  AuthSignInResultImpl(this.credential);

  @override
  bool get hasInfo => true;
}

const restProviderId = '_rest';

abstract class AuthCredentialRest implements AuthCredential {}

class AuthCredentialRestImpl implements AuthCredentialRest {
  @override
  final String providerId;

  AuthCredentialRestImpl({this.providerId = restProviderId});

  @override
  String toString() => 'AuthCredentialRest($providerId)';
}

class UserCredentialRestImpl implements UserCredential {
  @override
  final AuthCredentialRestImpl credential;

  @override
  final UserRest user;

  UserCredentialRestImpl(this.credential, this.user);

  @override
  String toString() => '$user $credential';
}

class AuthCredentialImpl implements AuthCredential {
  @override
  final String providerId;

  AuthCredentialImpl({this.providerId = localProviderId});

  @override
  String toString() => 'AuthCredential($providerId)';
}

class UserRecordRest implements UserRecord {
  UserRecordRest({required this.disabled, required this.emailVerified});

  @override
  dynamic get customClaims => null;

  @override
  final bool disabled;

  @override
  String? displayName;

  @override
  String? email;

  @override
  final bool emailVerified;

  @override
  UserMetadata? get metadata => null;

  @override
  String? get passwordHash => null;

  @override
  String? get passwordSalt => null;

  @override
  String? get phoneNumber => null;

  @override
  String? photoURL;

  @override
  List<UserInfo>? get providerData => null;

  @override
  String? get tokensValidAfterTime => null;

  @override
  late String uid;

  UserInfo toUserInfo() {
    return UserInfoRest(uid: uid, provider: null)
      ..email = email
      ..displayName = displayName;
  }

  User toUser() {
    return UserRest(
        uid: uid,
        emailVerified: emailVerified,
        provider: null,
        client: null,
      )
      ..email = email
      ..displayName = displayName;
  }

  @override
  String toString() {
    return 'email: $email ($emailVerified) $displayName, $uid';
  }
}

class UserInfoRest implements UserInfo, UserInfoWithIdToken {
  AccessCredentials? accessCredentials; // For current user only
  final AuthProviderRest? provider;
  @override
  String? displayName;

  @override
  String? email;

  UserInfoRest({required this.uid, this.provider});

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  String get providerId => localProviderId;

  @override
  final String uid;

  @override
  String toString() => '$uid $email $displayName';

  @override
  Future<String> getIdToken({bool? forceRefresh}) async {
    if (provider != null) {
      return provider!.getIdToken(forceRefresh: forceRefresh);
    }
    throw UnsupportedError('message');
  }
}

abstract class UserCredentialRest implements UserCredential {}

class UserCredentialEmailPasswordRestImpl implements UserCredentialRest {
  final identitytoolkit_v3.VerifyPasswordResponse signInResponse;
  @override
  final AuthCredential credential;

  @override
  final User user;

  UserCredentialEmailPasswordRestImpl(
    this.signInResponse,
    this.credential,
    this.user,
  );

  @override
  String toString() => '$user $credential';
}

/// Compat
typedef UserRest = FirebaseUserRest;

/// Top level class
class FirebaseUserRest extends UserInfoRest implements User {
  @override
  final bool emailVerified;

  final Client? client;

  FirebaseUserRest({
    required this.emailVerified,
    this.client,
    required super.uid,
    required super.provider,
  });

  @override
  bool get isAnonymous => false;

  @override
  String toString() {
    return '${super.toString()}, emailVerified: $emailVerified';
  }
}

/// Compat
typedef AuthRest = FirebaseAuthRest;

/// Custom auth rest
abstract class FirebaseAuthRest implements FirebaseAuth {
  Client? get client;

  /// Custom AuthRest
  factory FirebaseAuthRest({
    required FirebaseAuthServiceRest authService,
    required FirebaseAppRest appRest,
    String? rootUrl,
    String? servicePathBase,
  }) {
    return AuthRestImpl(
      authService,
      appRest,
      rootUrl: rootUrl,
      servicePathBase: servicePathBase,
    );
  }

  void addProviderImpl(AuthProviderRest authProviderRest);
}

/// Rest specific helper for adding a provider.
extension AuthRestExt on FirebaseAuth {
  void addProvider(AuthProviderRest authProviderRest) =>
      (this as FirebaseAuthRest).addProviderImpl(authProviderRest);
}

/// Common management
mixin AuthRestMixin {
  final providers = <AuthProviderRest>[];

  void addProviderImpl(AuthProviderRest authProviderRest) {
    providers.add(authProviderRest);
  }
}

class _ProviderUser {
  final AuthProvider provider;
  final UserRest? user;

  _ProviderUser(this.provider, this.user);
}

class AuthRestImpl
    with FirebaseAppProductMixin<FirebaseAuth>, AuthMixin, AuthRestMixin
    implements FirebaseAuthRest {
  final FirebaseAuthServiceRest serviceRest;
  @override
  Client? client;

  final _providerUserController = StreamController<_ProviderUser?>.broadcast();
  _ProviderUser? _currentProviderUser;

  AuthSignInResultRest? signInResultRest;
  final FirebaseAppRest _appRest;

  IdentityToolkitApi? _identitytoolkitApi;
  String? rootUrl;
  String? servicePathBase;

  @override
  User? get currentUser => _currentProviderUser?.user;

  IdentityToolkitApi get identitytoolkitApi => _identitytoolkitApi ??= () {
    if (rootUrl != null || servicePathBase != null) {
      var defaultRootUrl = 'https://www.googleapis.com/';

      var defaultServicePath = 'identitytoolkit/v3/relyingparty/';
      return IdentityToolkitApi(
        _appRest.client!,
        servicePath: servicePathBase == null
            ? defaultServicePath
            : '$servicePathBase/$defaultServicePath',
        rootUrl: rootUrl ?? defaultRootUrl,
      );
    } else {
      return IdentityToolkitApi(_appRest.client!);
    }
  }();

  void _setCurrentProviderUser(_ProviderUser? providerUser) {
    _currentProviderUser = providerUser;
    _providerUserController.sink.add(providerUser);

    if (providerUser?.user != null) {
      // Needed?
      client = (providerUser!.provider as AuthProviderRest).currentAuthClient;
    } else if (providerUser != null) {
      if (_currentProviderUser?.provider == providerUser.provider) {
        client = null;
      }
    }
    // ignore: deprecated_member_use
    _appRest.client = client;
  }

  final _currentUserInitLock = Lock();

  AuthRestImpl(
    this.serviceRest,
    this._appRest, {
    this.rootUrl,
    this.servicePathBase,
  }) {
    client = _appRest.client;
    if (debugFirebaseAuthRest) {
      _log('AuthRest(client: $client) is this a service account?');
    }
    // Copy auth client upon connection

    var firstCurrentUserCompleter = Completer<_ProviderUser?>();
    // Wait providers to be added.
    _currentUserInitLock.synchronized(
      () => Future.value(null)
          .then((_) {
            // Get initial user
            var futures = <Future>[];
            if (debugFirebaseAuthRest) {
              _log('providers: $providers');
            }
            for (var provider in providers) {
              futures.add(
                provider.onCurrentUser.first.then((user) {
                  if (user != null) {
                    if (!firstCurrentUserCompleter.isCompleted) {
                      firstCurrentUserCompleter.complete(
                        _ProviderUser(provider, user),
                      );
                    }
                  }
                }),
              );
            }
            Future.wait(futures).then((_) {
              if (!firstCurrentUserCompleter.isCompleted) {
                firstCurrentUserCompleter.complete(null);
              }
            });
            return firstCurrentUserCompleter.future;
          })
          .then((firstCurrentUser) {
            _setCurrentProviderUser(firstCurrentUser);
          }),
    );
  }

  //String get localPath => _appLocal?.localPath;

  // Take first provider
  @override
  Stream<User?> get onCurrentUser async* {
    await _currentUserInitLock.synchronized(() {});
    yield _currentProviderUser?.user;

    await for (var providerUser in _providerUserController.stream) {
      yield providerUser?.user;
    }
  }

  @override
  Future<ListUsersResult> listUsers({
    int? maxResults,
    String? pageToken,
  }) async {
    throw UnsupportedError('listUsers');
  }

  @override
  Future<UserRecord?> getUser(String uid) async {
    var request = IdentitytoolkitRelyingpartyGetAccountInfoRequest()
      ..localId = [uid];
    if (debugFirebaseAuthRest) {
      _log('getAccountInfoRequest: ${jsonPretty(request.toJson())}');
    }
    var result = await identitytoolkitApi.relyingparty.getAccountInfo(request);
    if (debugFirebaseAuthRest) {
      _log('getAccountInfo: ${jsonPretty(result.toJson())}');
    }
    if (result.users?.isNotEmpty ?? false) {
      var restUserInfo = result.users!.first;
      return toUserRecord(restUserInfo);
    }
    return null;
  }

  @override
  Future<List<UserRecord>> getUsers(List<String> uids) async {
    var request = IdentitytoolkitRelyingpartyGetAccountInfoRequest()
      ..localId = uids;
    if (debugFirebaseAuthRest) {
      _log('getAccountInfoRequest: ${jsonPretty(request.toJson())}');
    }
    var result = await identitytoolkitApi.relyingparty.getAccountInfo(request);
    if (debugFirebaseAuthRest) {
      _log('getAccountInfo: ${jsonPretty(result.toJson())}');
    }
    var users = (result.users ?? <api.UserInfo>[]);
    return users
        .map((restUserInfo) => toUserRecord(restUserInfo))
        .toList(growable: false);
  }

  @override
  Future<UserRecord> getUserByEmail(String email) async {
    throw UnsupportedError('getUserByEmail');
  }

  @override
  Future<AuthSignInResult> signIn(
    AuthProvider authProvider, {
    AuthSignInOptions? options,
  }) async {
    if (authProvider is AuthProviderRest) {
      var result = await authProvider.signIn();
      if (result is AuthSignInResultRest) {
        client = result.client;
        // Set in global too.
        // ignore: deprecated_member_use
        _appRest.client = client;
        signInResultRest = result;
      }
      return result;
    } else {
      throw UnsupportedError('signIn');
    }
  }

  @override
  Future signOut() async {
    try {
      await signInResultRest?.provider.signOut();
    } catch (e) {
      print('signOut error $e');
    }
  }

  @override
  String toString() => _appRest.name;

  @override
  Future<DecodedIdToken> verifyIdToken(
    String idToken, {
    bool? checkRevoked,
  }) async {
    throw UnsupportedError('verifyIdToken');
  }

  @override
  Future<User> reloadCurrentUser() {
    throw UnsupportedError('reloadCurrentUser');
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    var client = EmailPasswordLoginClient(apiKey: _appRest.options.apiKey!);
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
        provider: EmailPasswordAuthProviderRest(),
        uid: response.localId!,
      ),
    );
    // ignore: deprecated_member_use
    _appRest.client = EmailPasswordLoggedInClient(
      userCredential: userCredential,
    );
    return UserCredentialEmailPasswordRestImpl(
      response,
      AuthCredentialRestImpl(),
      UserRest(
        client: client,
        emailVerified: false,
        provider: EmailPasswordAuthProviderRest(),
        uid: response.localId!,
      ),
    );
  }

  @override
  FirebaseApp get app => _appRest;

  @override
  FirebaseAuthService get service => serviceRest;
}

class DecodedIdTokenLocal implements DecodedIdToken {
  @override
  final String uid;

  DecodedIdTokenLocal({required this.uid});
}

class FirebaseAuthServiceRest
    with FirebaseProductServiceMixin<FirebaseAuth>
    implements FirebaseAuthService {
  @override
  bool get supportsListUsers => false;

  @override
  FirebaseAuthRest auth(App app) {
    return getInstance(app, () {
      assert(app is FirebaseAppRest, 'invalid app type - not AppLocal');
      final appRest = app as FirebaseAppRest;
      // final appLocal = app as AppLocal;
      return AuthRestImpl(this, appRest);
    });
  }

  @override
  bool get supportsCurrentUser => true;
}

FirebaseAuthServiceRest? _authServiceRest;

FirebaseAuthServiceRest get _firebaseAuthServiceRest =>
    _authServiceRest ??= FirebaseAuthServiceRest();

/// Compat
FirebaseAuthServiceRest get authServiceRest => _firebaseAuthServiceRest;

/// auth service
FirebaseAuthServiceRest get firebaseAuthServiceRest =>
    _firebaseAuthServiceRest; //firebaseAuthServiceRest;

/// Compat
typedef AuthServiceRest = FirebaseAuthServiceRest;
//
//FirebaseAuthServiceRest get authService => authServiceLocal;

class AuthAccountApi {
  final String apiKey;
  var client = Client();

  AuthAccountApi({required this.apiKey});

  //  Future signInWithIdp() {}
  void dispose() {
    client.close();
  }
}

/// Extra rest information
abstract class AuthProviderRest implements AuthProvider {
  Future<AuthSignInResult> signIn();

  Stream<FirebaseUserRest?> get onCurrentUser;

  Future<String> getIdToken({bool? forceRefresh});

  Future<void> signOut();

  /// Current auto client
  AuthClient get currentAuthClient;
}

UserRecord toUserRecord(api.UserInfo restUserInfo) {
  var userRecord = UserRecordRest(
    emailVerified: restUserInfo.emailVerified ?? false,
    disabled: false,
  );
  userRecord.email = restUserInfo.email;
  userRecord.displayName = restUserInfo.displayName;
  userRecord.uid = restUserInfo.localId!;
  userRecord.photoURL = restUserInfo.photoUrl;
  return userRecord;
}

typedef PromptUserForConsentRest = void Function(String uri);
