import 'package:path/path.dart';
import 'package:tekartik_firebase_test/ci_shell_io.dart';

var topDir = join('..', '..');

Future<void> main() async {
  var shell = firebaseGithubActionEnvTestShell(join(topDir, 'firebase_rest'));
  await shell.run('dart test test/firebase_rest_env_io_test.dart');
}
