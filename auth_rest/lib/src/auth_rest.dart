import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/stream/stream_join.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_auth_rest/src/identitytoolkit/v3.dart'
    hide UserInfo;
import 'package:tekartik_firebase_auth_rest/src/identitytoolkit/v3.dart' as api;
import 'package:tekartik_firebase_rest/firebase_rest.dart';

import 'auth_rest_built_in_provider.dart';
import 'auth_rest_provider.dart';
import 'auth_service_rest.dart';
import 'google_auth_rest.dart';
import 'import.dart';

/// Debug rest (to move to firebase rest)
var debugFirebaseAuthRest = false; // devWarning(true);
// var debugFirebaseAuthRest = devWarning(true);

void _log(Object? message) {
  // ignore: avoid_print
  print(message);
}

/// Local provider id
const localProviderId = '_local';

/*
class AuthLocalSignInOptions implements AuthSignInOptions {
  final UserRecordRest _userRecordLocal;

  AuthLocalSignInOptions(this._userRecordLocal);
}

 */

/// List users result implementation
class ListUsersResultRest implements ListUsersResult {
  @override
  final String pageToken;

  @override
  final List<UserRecord> users;

  /// Create list users result
  ListUsersResultRest({required this.pageToken, required this.users});
}

/// Sign in result implementation
class AuthSignInResultImpl implements AuthSignInResult {
  @override
  final UserCredential credential;

  /// Create auth sign in result
  AuthSignInResultImpl(this.credential);

  @override
  bool get hasInfo => true;
}

/// Rest provider id
const restProviderId = '_rest';

/// Auth credential rest implementation
abstract class AuthCredentialRest implements AuthCredential {}

/// Auth credential rest implementation
class AuthCredentialRestImpl implements AuthCredentialRest {
  @override
  final String providerId;

  /// Create auth credential
  AuthCredentialRestImpl({this.providerId = restProviderId});

  @override
  String toString() => 'AuthCredentialRest($providerId)';
}

/// User credential rest implementation
abstract class UserCredentialRestImpl implements UserCredentialRest {
  @override
  final AuthCredentialRestImpl credential;

  @override
  final UserRest user;

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

/// User record REST implementation
class UserRecordRest with FirebaseUserRecordDefaultMixin implements UserRecord {
  /// Create user record
  UserRecordRest({
    required this.disabled,
    required this.emailVerified,
    required this.isAnonymous,
  });

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
  final bool isAnonymous;

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

  /// Convert to user info
  UserInfo toUserInfo() {
    return UserInfoRest(uid: uid, provider: null)
      ..email = email
      ..displayName = displayName;
  }

  /// Convert to user
  User toUser() {
    return UserRest(
        uid: uid,
        emailVerified: emailVerified,
        provider: null,
        client: null,
        isAnonymous: false,
      )
      ..email = email
      ..displayName = displayName;
  }

  @override
  String toString() {
    return 'email: $email ($emailVerified) $displayName, $uid';
  }
}

/// User info rest implementation
class UserInfoRest implements UserInfo, UserInfoWithIdToken {
  /// Access credentials
  AccessCredentials? accessCredentials; // For current user only
  /// Provider
  final AuthProviderRest? provider;
  @override
  String? displayName;

  @override
  String? email;

  /// Create user info
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

/// User credential rest implementation
abstract class UserCredentialRest implements UserCredential {
  /// The id token
  String get idToken;

  /// Create user credential
  factory UserCredentialRest({
    required AuthCredential credential,
    required FirebaseUser user,
    required String idToken,
  }) {
    return _UserCredentialRestLive(
      credential: credential,
      user: user,
      idToken: idToken,
    );
  }
}

class _UserCredentialRestLive implements UserCredentialRest {
  @override
  final AuthCredential credential;

  @override
  final User user;

  @override
  final String idToken;

  _UserCredentialRestLive({
    required this.credential,
    required this.user,
    required this.idToken,
  });
}

/// Compat
typedef UserRest = FirebaseUserRest;

/// Top level class
class FirebaseUserRest extends UserInfoRest implements User {
  @override
  /// Whether the email is verified
  final bool emailVerified;

  /// The client
  final Client? client;

  @override
  final bool isAnonymous;

  /// Create firebase user
  FirebaseUserRest({
    required this.emailVerified,
    this.client,
    required this.isAnonymous,
    required super.uid,
    required super.provider,
  });

  @override
  String toString() {
    return '${super.toString()}, emailVerified: $emailVerified${isAnonymous ? ', anonymous' : ''}';
  }
}

/// Compat
typedef AuthRest = FirebaseAuthRest;

/// Custom auth rest
abstract class FirebaseAuthRest implements FirebaseAuth {
  /// The client
  Client? get client;

  /// Custom AuthRest
  factory FirebaseAuthRest({
    required FirebaseAuthServiceRest authService,
    required FirebaseAppRest appRest,
    String? rootUrl,
    String? servicePathBase,
  }) {
    return FirebaseAuthRestImpl(
      authService,
      appRest,
      rootUrl: rootUrl,
      servicePathBase: servicePathBase,
    );
  }
}

/// Rest specific helper for adding a provider.
extension FirebaseAuthRestExt on FirebaseAuth {
  /// Add a provider
  void addProvider(AuthProviderRest authProviderRest) =>
      impl.addProviderImpl(authProviderRest);
}

/// Private extension
extension FirebaseAuthRestPrvExt on FirebaseAuth {
  /// Service rest
  FirebaseAuthServiceRest get serviceRest => service as FirebaseAuthServiceRest;

  /// Impl access
  FirebaseAuthRestImpl get impl => this as FirebaseAuthRestImpl;
}

/// Common management
mixin FirebaseAuthRestMixin implements FirebaseAuthRest {
  /// Add a provider
  void addProviderImpl(AuthProviderRest authProviderRest) {
    impl.providers.add(authProviderRest);
  }
}

class _ProviderUser {
  final AuthProvider provider;
  final UserRest? user;

  _ProviderUser(this.provider, this.user);
}

/// Auth rest implementation
class FirebaseAuthRestImpl
    with FirebaseAppProductMixin<FirebaseAuth>, AuthMixin, FirebaseAuthRestMixin
    implements FirebaseAuthRest {
  /// Service
  final FirebaseAuthServiceRest serviceRest;

  /// Providers
  late final providers = () {
    var providers = serviceRest.prv.providersCallback();
    for (var provider in providers) {
      provider.mixin.init(this);
    }
    return providers;
  }();

  /// Built-in provider
  late final builtInProvider = providers
      .whereType<BuiltInAuthProviderRest>()
      .first;

  @override
  // Client
  Client? client;

  StreamSubscription? _providerCurrentUserChangesSubscription;
  final _authReadyCompleter = Completer<bool>();

  /// Auth ready future to use before signIn,out,currentUser...
  late final authReady = () {
    _trackCurrentUserChanges();
    return _authReadyCompleter.future;
  }();

  void _trackCurrentUserChanges() {
    _providerCurrentUserChangesSubscription ??= () {
      var providers = this.providers.toList();
      var streams = providers.map((p) => p.onCurrentUser).toList();
      _providerCurrentUserChangesSubscription = streamJoinAll(streams).listen((
        users,
      ) {
        try {
          var index = users.indexWhere((user) => user != null);
          if (index >= 0) {
            var provider = providers[index];
            var user = users[index]!;
            _setCurrentProviderUser(_ProviderUser(provider, user));
            return;
          }

          /// Take first non null user
          _setCurrentProviderUser(null);
        } finally {
          _authReadyCompleter.safeComplete(true);
        }
      });
    }();
  }

  _ProviderUser? _currentProviderUser;
  final _providerUserController = StreamController<_ProviderUser?>.broadcast(
    sync: true,
  );

  /// Sign in result
  AuthSignInResultRest? signInResultRest;

  /// App rest
  final FirebaseAppRest appRest;

  IdentityToolkitApi? _identitytoolkitApi;

  /// Root url
  String? rootUrl;

  /// Service path base
  String? servicePathBase;

  @override
  User? get currentUser => _currentProviderUser?.user;

  /// Identity toolkit api
  IdentityToolkitApi get identitytoolkitApi => _identitytoolkitApi ??= () {
    if (rootUrl != null || servicePathBase != null) {
      var defaultRootUrl = 'https://www.googleapis.com/';

      var defaultServicePath = 'identitytoolkit/v3/relyingparty/';
      return IdentityToolkitApi(
        appRest.client!,
        servicePath: servicePathBase == null
            ? defaultServicePath
            : '$servicePathBase/$defaultServicePath',
        rootUrl: rootUrl ?? defaultRootUrl,
      );
    } else {
      return IdentityToolkitApi(appRest.apiClient);
    }
  }();

  void _setCurrentProviderUser(_ProviderUser? providerUser) {
    _currentProviderUser = providerUser;
    _providerUserController.sink.add(providerUser);

    Client? client;
    if (providerUser != null) {
      if (providerUser.user != null) {
        // Needed?
        client = (providerUser.provider as AuthProviderRest).currentAuthClient;
      } else {
        if (_currentProviderUser?.provider == providerUser.provider) {
          client = null;
        }
      }
    }
    // ignore: deprecated_member_use
    appRest.client = client;
  }

  /// Create auth rest
  FirebaseAuthRestImpl(
    this.serviceRest,
    this.appRest, {
    this.rootUrl,
    this.servicePathBase,
  }) {
    client = appRest.client;
    if (debugFirebaseAuthRest) {
      _log('AuthRest(client: $client) is this a service account?');
    }
    // Copy auth client upon connection
    return;
  }

  @override
  void dispose() {
    _providerCurrentUserChangesSubscription?.cancel();
    _providerUserController.close();
    _currentProviderUser = null;
    super.dispose();
  }

  //String get localPath => _appLocal?.localPath;

  // Take first provider
  @override
  Stream<User?> get onCurrentUser async* {
    await authReady;
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
        appRest.client = client;
        signInResultRest = result;
      }
      return result;
    } else {
      throw UnsupportedError('signIn');
    }
  }

  @override
  Future signOut() async {
    await authReady;
    await _currentProviderUser?.provider.mixin.signOut();
    // ignore: deprecated_member_use
    appRest.client = null;
  }

  @override
  String toString() => appRest.name;

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
  Future<UserCredential> signInAnonymously() async {
    await authReady;
    return builtInProvider.signInAnonymously();
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await authReady;
    return builtInProvider.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  FirebaseApp get app => appRest;

  @override
  FirebaseAuthService get service => serviceRest;
}

/// Decoded ID token local implementation
class DecodedIdTokenLocal implements DecodedIdToken {
  @override
  final String uid;

  /// Create decoded id token local
  DecodedIdTokenLocal({required this.uid});
}

//FirebaseAuthServiceRest get authService => authServiceLocal;

/// Rest account api
class AuthAccountApi {
  /// The api key
  final String apiKey;

  /// The client
  var client = Client();

  /// Create auth account api
  AuthAccountApi({required this.apiKey});

  //  Future signInWithIdp() {}
  /// Dispose
  void dispose() {
    client.close();
  }
}

/// Convert [api.UserInfo] to [UserRecord]
UserRecord toUserRecord(api.UserInfo restUserInfo) {
  var userRecord = UserRecordRest(
    emailVerified: restUserInfo.emailVerified ?? false,
    disabled: false,
    isAnonymous: false,
  );
  userRecord.email = restUserInfo.email;
  userRecord.displayName = restUserInfo.displayName;
  userRecord.uid = restUserInfo.localId!;
  userRecord.photoURL = restUserInfo.photoUrl;
  return userRecord;
}

/// Prompt user for consent callback
typedef PromptUserForConsentRest = void Function(String uri);
