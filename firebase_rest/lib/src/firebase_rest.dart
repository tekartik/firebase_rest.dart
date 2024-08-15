import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/firebase_admin.dart';
import 'package:tekartik_firebase/src/firebase_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_rest/firebase_rest.dart';

import 'firebase_app_rest.dart';
import 'platform.dart';

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
  Future<FirebaseApp> initializeAppWithServiceAccountMap(Map map) async {
    var credentials = FirebaseAdminCredentialRest.fromServiceAccountMap(map);
    credential.setApplicationDefault(credentials);
    return await initializeAppAsync();
  }

  /// Initialize rest with a service account json string.
  Future<FirebaseApp> initializeAppWithServiceAccountString(
      String serviceAccountString) async {
    var credentials = FirebaseAdminCredentialRest.fromServiceAccountJson(
        serviceAccountString);
    credential.setApplicationDefault(credentials);
    return await initializeAppAsync();
  }
}

/// Compat
typedef AppOptionsRest = FirebaseAppOptionsRest;

/// The app options to use for REST app initialization.
abstract class FirebaseAppOptionsRest extends AppOptions {
  /// The http client
  @Deprecated('Use client in auth')
  Client? get client;

  /// Create a new options object.
  factory FirebaseAppOptionsRest(
          {@Deprecated('Use client') AuthClient? authClient, Client? client}) =>
      // ignore: deprecated_member_use_from_same_package
      AppOptionsRestImpl(authClient: authClient, client: client);
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
  @Deprecated('Use client')

  /// Compat
  AuthClient? get authClient =>
      (client is AuthClient) ? (client as AuthClient?) : null;
  @override
  final Client? client;

  /// authClient will be deprecated.
  AppOptionsRestImpl(
      {@Deprecated('Use client') AuthClient? authClient, Client? client})
      : client = client ?? authClient {
    if (client != null) {
      assert(authClient == null);
    }
    // assert(this.client != null);
  }
}

/// Rest implementation.
class FirebaseRestImpl with FirebaseMixin implements FirebaseAdminRest {
  @override
  App initializeApp({AppOptions? options, String? name}) {
    name ??= firebaseRestDefaultAppName;
    var app = AppRestImpl(
      name: name,
      firebaseRest: this,
      options: (options ??
          (credential.applicationDefault() as FirebaseAdminCredentialRest)
              .appOptions)!,
    );
    _apps[app.name] = FirebaseMixin.latestFirebaseInstanceOrNull = app;
    return app;
  }

  @override
  Future<App> initializeAppAsync({AppOptions? options, String? name}) async {
    // initialize client
    await credential.applicationDefault()?.getAccessToken();
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
}

/// Rest credentials implementation
abstract class FirebaseAdminCredentialRest implements FirebaseAdminCredential {
  /// App options
  AppOptionsRest? get appOptions;

  /// Auth client
  AuthClient? get authClient;

  /// from service account json string
  factory FirebaseAdminCredentialRest.fromServiceAccountJson(
      String serviceAccountJson,
      {List<String>? scopes}) {
    return newFromServiceAccountJson(serviceAccountJson, scopes: scopes);
  }

  /// from service account map
  factory FirebaseAdminCredentialRest.fromServiceAccountMap(
      Map serviceAccountMap,
      {List<String>? scopes}) {
    return newFromServiceAccountMap(serviceAccountMap, scopes: scopes);
  }
}
