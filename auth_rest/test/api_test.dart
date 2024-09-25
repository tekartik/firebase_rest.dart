import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest_web.dart';
import 'package:test/test.dart';

Future main() async {
  group('api', () {
    test('web', () async {
      try {
        GoogleAuthProviderRestWeb(options: GoogleAuthOptions());
        expect(isRunningAsJavascript, isTrue);
      } on UnsupportedError catch (_) {
        // Web: UnimplementedError: databaseFactoryIo not supported on the web. use `sembast_web`
      }
    });
    test('open', () async {
      try {
        // createDatabaseFactoryIo();
        // expect(isRunningAsJavascript, isFalse);
      } on UnimplementedError catch (_) {
        // Web: UnimplementedError: databaseFactoryIo not supported on the web. use `sembast_web`
      }
    });
  });
}
