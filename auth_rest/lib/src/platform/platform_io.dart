import 'package:tekartik_firebase_auth_rest/src/google_auth_rest.dart';

export 'package:tekartik_firebase_auth_rest/src/google_auth_rest_io.dart'
    show GoogleAuthProviderRestIo;

abstract class GoogleAuthProviderRestWeb implements GoogleRestAuthProvider {
  factory GoogleAuthProviderRestWeb({required GoogleAuthOptions options}) =>
      throw UnsupportedError('web');
}
