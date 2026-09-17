import 'package:path/path.dart';
import 'package:tekartik_firebase_test/ci_shell_io.dart';

var topDir = join('..', '..');

Future<void> main() async {
  var shell = firebaseGithubActionEnvTestShell(join(topDir, 'auth_rest'));
  await shell.run('dart test test/auth_rest_io_env_test.dart');
}
