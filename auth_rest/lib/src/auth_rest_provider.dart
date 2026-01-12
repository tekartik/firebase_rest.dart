import 'package:http/http.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest_io.dart';

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
      currentAuthClient = LoggedInClient(userCredential: userCredential);
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

  /// Save user credential
  Future<void> saveUser(UserCredentialRest? user) async {}

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
  /// Get id token.
  @override
  Future<String> getIdToken({bool? forceRefresh}) {
    // TODO: implement getIdToken
    throw UnimplementedError();
  }

  /// Sign in.
  @override
  Future<AuthSignInResult> signIn() {
    // TODO: implement signIn
    throw UnimplementedError();
  }
}
