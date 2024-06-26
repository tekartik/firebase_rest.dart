import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/firebase_admin.dart';
import 'package:tekartik_firebase/src/firebase_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_rest/firebase_rest.dart';

import 'platform.dart';

String get _defaultAppName => firebaseAppNameDefault;

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

/// The app options to use for REST app initialization.
abstract class AppOptionsRest extends AppOptions {
  /// The http client
  @Deprecated('Use client in auth')
  Client? get client;

  /// Create a new options object.
  factory AppOptionsRest(
          {@Deprecated('Use client') AuthClient? authClient, Client? client}) =>
      // ignore: deprecated_member_use_from_same_package
      AppOptionsRestImpl(authClient: authClient, client: client);
}

var firebaseRest = FirebaseRestImpl();

// const String googleApisAuthDatastoreScope =
//    'https://www.googleapis.com/auth/datastore';
const String googleApisAuthCloudPlatformScope =
    'https://www.googleapis.com/auth/cloud-platform';

class AppOptionsRestImpl extends AppOptions implements AppOptionsRest {
  @Deprecated('Use client')
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

class FirebaseRestImpl with FirebaseMixin implements FirebaseAdminRest {
  @override
  App initializeApp({AppOptions? options, String? name}) {
    name ??= _defaultAppName;
    var impl = AppRestImpl(
      name: name,
      firebaseRest: this,
      options: (options ??
          (credential.applicationDefault() as FirebaseAdminCredentialRest)
              .appOptions)!,
    );
    _apps[impl.name] = impl;
    return impl;
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
    name ??= _defaultAppName;
    return _apps[name]!;
  }

  FirebaseAdminCredentialServiceRest? _credentialServiceRest;

  @override
  FirebaseAdminCredentialService get credential =>
      _credentialServiceRest ??= FirebaseAdminCredentialServiceRest(this);
}

FirebaseRestImpl? _impl;

FirebaseRestImpl get impl => _impl ??= FirebaseRestImpl();

/// Mixin
mixin FirebaseAppRestMixin {
  Client? currentAuthClient;
}

/// App Rest
class AppRestImpl
    with FirebaseAppMixin, FirebaseAppRestMixin
    implements AppRest {
  final FirebaseRestImpl firebaseRest;

  @override
  final AppOptions options;

  bool deleted = false;
  @override
  late final String name;

  AppRestImpl(
      {required this.firebaseRest, required this.options, String? name}) {
    this.name = name ?? _defaultAppName;
    var options = this.options;
    if (options is AppOptionsRest) {
      // Compat
      // ignore: deprecated_member_use_from_same_package
      currentAuthClient = options.client;
    }
  }

  @override
  Future<void> delete() async {
    deleted = true;
    await closeServices();
  }

  @override
  @Deprecated('Use client')
  AuthClient? get authClient => currentAuthClient as AuthClient;

  @override
  Client? get client => currentAuthClient;

  @override
  set client(Client? client) => currentAuthClient = client;
}

class FirebaseAdminAccessTokenRest implements FirebaseAdminAccessToken {
  @override
  final String data;

  FirebaseAdminAccessTokenRest({required this.data});

  @override
  int get expiresIn => 0;
}

class FirebaseAdminCredentialServiceRest
    implements FirebaseAdminCredentialService {
  final FirebaseRestImpl firebaseRest;

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
  AppOptionsRest? get appOptions;

  AuthClient? get authClient;

  factory FirebaseAdminCredentialRest.fromServiceAccountJson(
      String serviceAccountJson,
      {List<String>? scopes}) {
    return newFromServiceAccountJson(serviceAccountJson, scopes: scopes);
  }

  factory FirebaseAdminCredentialRest.fromServiceAccountMap(
      Map serviceAccountMap,
      {List<String>? scopes}) {
    return newFromServiceAccountMap(serviceAccountMap, scopes: scopes);
  }
}
