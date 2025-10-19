import 'package:cv/cv.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:tekartik_firebase/firebase_admin.dart';
import 'package:tekartik_firebase/src/firebase_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_rest/firebase_rest.dart';

import 'firebase_app_rest.dart';
import 'firebase_rest_io.dart';

/// Debug flag for firebase rest
bool debugFirebaseRest = false;

/// Compat
bool get debugRest =>
    debugFirebaseRest; // devWarning(true); // false// devWarning(true); // false
@Deprecated('Use debugFirebaseRest')
set debugRest(bool value) {
  debugFirebaseRest = value;
}

/// Default app name
String get firebaseRestDefaultAppName => firebaseAppNameDefault;

/// Rest options.
abstract class AdminAppOptionsRest implements AppOptionsRest {
  /// The http client
  @override
  Client? get client;
}

/// Rest extension.
extension FirebaseAdminRestExtension on FirebaseAdminRest {
  /// Initialize rest with a service account json map.
  Future<FirebaseApp> initializeAppWithServiceAccountMap(
    Map map, {

    /// Overriden options (storage bucket, database url, ...)
    FirebaseAppOptions? options,
    List<String>? scopes,
  }) async {
    var credentials = FirebaseAdminCredentialRest.fromServiceAccountMap(
      map,

      scopes: scopes,
    );
    credential.setApplicationDefault(credentials);
    return await initializeAppAsync(options: options);
  }

  /// Initialize rest with a service account json string.
  Future<FirebaseApp> initializeAppWithServiceAccountString(
    String serviceAccountString, {

    /// Overriden options (storage bucket, database url, ...)
    FirebaseAppOptions? options,
    List<String>? scopes,
  }) async {
    var credentials = FirebaseAdminCredentialRest.fromServiceAccountJson(
      serviceAccountString,
      scopes: scopes,
    );
    credential.setApplicationDefault(credentials);
    return await initializeAppAsync(options: options);
  }
}

/// Compat
typedef AppOptionsRest = FirebaseAppOptionsRest;

/// The app options to use for REST app initialization.
abstract class FirebaseAppOptionsRest extends AppOptions {
  /// The identity service account if any
  FirebaseRestIdentifyServiceAccount? get identityServiceAccount;

  /// The http client
  @Deprecated('Use client in auth')
  Client? get client;

  /// Create a new options object.
  factory FirebaseAppOptionsRest({
    @Deprecated('Use client') AuthClient? authClient,
    Client? client,
    FirebaseRestIdentifyServiceAccount? identifyServiceAccount,
    String? apiKey,
    String? storageBucket,
  }) => AppOptionsRestImpl(
    // ignore: deprecated_member_use_from_same_package
    authClient: authClient,
    client: client,
    apiKey: apiKey,
    storageBucket: storageBucket,
    identityServiceAccount: identifyServiceAccount,
  );

  /// Create a copy with modified values.
  FirebaseAppOptionsRest copyWith({String? apiKey, String? storageBucket});
}

/// firebase rest instance.
var firebaseRest = FirebaseRestImpl();

// const String googleApisAuthDatastoreScope =
//    'https://www.googleapis.com/auth/datastore';
/// Auth scope
const String googleApisAuthCloudPlatformScope =
    'https://www.googleapis.com/auth/cloud-platform';

/// Firebase rest implementation.
class AppOptionsRestImpl extends FirebaseAppOptions implements AppOptionsRest {
  @override
  final FirebaseRestIdentifyServiceAccount? identityServiceAccount;
  @Deprecated('Use client')
  /// Compat
  AuthClient? get authClient =>
      (client is AuthClient) ? (client as AuthClient?) : null;
  @override
  final Client? client;

  /// authClient will be deprecated.
  AppOptionsRestImpl({
    @Deprecated('Use client') AuthClient? authClient,
    Client? client,
    super.projectId,
    super.apiKey,
    super.storageBucket,
    this.identityServiceAccount,
  }) : client = client ?? authClient {
    if (client != null) {
      assert(authClient == null);
    }
    // assert(this.client != null);
  }

  @override
  AppOptionsRestImpl copyWith({String? apiKey, String? storageBucket}) {
    return AppOptionsRestImpl(
      client: client,
      projectId: projectId,
      apiKey: apiKey ?? this.apiKey,
      storageBucket: storageBucket ?? this.storageBucket,

      identityServiceAccount: identityServiceAccount,
    );
  }
}

/// Rest implementation.
class FirebaseRestImpl with FirebaseMixin implements FirebaseAdminRest {
  @override
  App initializeApp({AppOptions? options, String? name}) {
    name ??= firebaseRestDefaultAppName;
    AppRestImpl app;
    var credentialsRest = credential
        .applicationDefault()
        ?.anyAs<FirebaseAdminCredentialRest?>();
    var restOptions = credentialsRest?.appOptions;
    if (options == null) {
      app = AppRestImpl(name: name, firebaseRest: this, options: restOptions!);
    } else {
      if (restOptions != null) {
        options = restOptions.copyWith(
          apiKey: options.apiKey,
          storageBucket: options.storageBucket,
        );
      }
      app = AppRestImpl(name: name, firebaseRest: this, options: options);
    }
    _apps[app.name] = FirebaseMixin.latestFirebaseInstanceOrNull = app;
    return app;
  }

  @override
  Future<App> initializeAppAsync({AppOptions? options, String? name}) async {
    var credentials = credential.applicationDefault();
    if (credentials is FirebaseAdminCredentialRestImpl) {
      await credentials.initAuthClient();
    }
    // old
    // initialize client
    //        await credential.applicationDefault()?.getAccessToken();
    var app = initializeApp(options: options, name: name);
    return app;
  }

  final _apps = <String?, AppRestImpl>{};

  @override
  App app({String? name}) {
    name ??= firebaseRestDefaultAppName;
    return _apps[name]!;
  }

  FirebaseAdminCredentialServiceRest? _credentialServiceRest;

  @override
  FirebaseAdminCredentialService get credential =>
      _credentialServiceRest ??= FirebaseAdminCredentialServiceRest(this);

  @override
  String toString() {
    return 'FirebaseRest($_credentialServiceRest)';
  }
}

FirebaseRestImpl? _impl;

/// Firebase rest instance.
FirebaseRestImpl get impl => _impl ??= FirebaseRestImpl();

/// Rest implementation.
class FirebaseAdminAccessTokenRest implements FirebaseAdminAccessToken {
  @override
  final String data;

  /// Rest implementation.
  FirebaseAdminAccessTokenRest({required this.data});

  @override
  int get expiresIn => 0;
}

/// Rest implementation.
class FirebaseAdminCredentialServiceRest
    implements FirebaseAdminCredentialService {
  /// Firebase rest implementation
  final FirebaseRestImpl firebaseRest;

  /// Rest implementation.
  FirebaseAdminCredentialServiceRest(this.firebaseRest);

  FirebaseAdminCredentialRest? _applicationDefault;

  @override
  FirebaseAdminCredential? applicationDefault() => _applicationDefault;

  // Must be called on setup
  @override
  void setApplicationDefault(FirebaseAdminCredential? credential) {
    _applicationDefault = credential as FirebaseAdminCredentialRest?;
  }

  @override
  String toString() =>
      'FirebaseAdminCredentialServiceRest($_applicationDefault)';
}

/// Compat
typedef FirebaseAdminCredentialRest = FirebaseAdminCredentialsRest;

/// Rest credentials implementation
abstract class FirebaseAdminCredentialsRest implements FirebaseAdminCredential {
  /// Initialize the auth client (service account only)
  Future<AuthClient> initAuthClient();

  /// Get the project Id (if available)
  String get projectId;

  /// App options
  AppOptionsRest? get appOptions;

  /// Auth client
  AuthClient? get authClient;

  /// from service account json string
  factory FirebaseAdminCredentialsRest.fromServiceAccountJson(
    String serviceAccountJson, {
    List<String>? scopes,
  }) {
    return firebaseAdminCredentialsFromServiceAccountJson(
      serviceAccountJson,
      scopes: scopes,
    );
  }

  /// from service account map
  factory FirebaseAdminCredentialsRest.fromServiceAccountMap(
    Map serviceAccountMap, {
    List<String>? scopes,
  }) {
    return firebaseAdminCredentialsFromServiceAccountMap(
      serviceAccountMap,
      scopes: scopes,
    );
  }
}
