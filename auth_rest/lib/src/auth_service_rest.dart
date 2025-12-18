// ignore: implementation_imports
import 'package:tekartik_firebase_rest/firebase_rest.dart';

import '../auth_rest.dart';
import 'auth_rest.dart';

class _FirebaseAuthServiceRest
    with FirebaseProductServiceMixin<FirebaseAuth>
    implements FirebaseAuthServiceRest {
  List<AuthProviderRest> Function() providersCallback;
  final FirebaseRestAuthPersistence? persistence;

  /// Constructor
  _FirebaseAuthServiceRest({
    this.persistence,
    List<AuthProviderRest> Function()? providers,
  }) : providersCallback = providers ?? (() => [BuiltInAuthProviderRest()]);
  @override
  /// Whether list users is supported
  bool get supportsListUsers => false;

  @override
  FirebaseAuthRest auth(App app) {
    return getInstance(app, () {
      assert(app is FirebaseAppRest, 'invalid app type - not AppLocal');
      final appRest = app as FirebaseAppRest;
      // final appLocal = app as AppLocal;
      return FirebaseAuthRestImpl(this, appRest);
    });
  }

  @override
  bool get supportsCurrentUser => true;
}

/// Private extension to access private members
extension FirebaseAuthServiceRestPrvExt on FirebaseAuthService {
  /// Mixin access
  // ignore: library_private_types_in_public_api
  _FirebaseAuthServiceRest get prv => this as _FirebaseAuthServiceRest;
}

/// Auth service rest implementation
abstract class FirebaseAuthServiceRest implements FirebaseAuthService {
  /// Constructor
  factory FirebaseAuthServiceRest({
    FirebaseRestAuthPersistence? persistence,
    List<AuthProviderRest> Function()? providers,
  }) =>
      _FirebaseAuthServiceRest(persistence: persistence, providers: providers);

  @override
  FirebaseAuthRest auth(App app);
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
