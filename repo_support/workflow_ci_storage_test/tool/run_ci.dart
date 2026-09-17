import 'package:path/path.dart';
import 'package:tekartik_firebase_test/ci_shell_io.dart';

var topDir = join('..', '..');

Future<void> main() async {
  var shell = firebaseGithubActionEnvTestShell(join(topDir, 'storage_rest'));
  await shell.run('dart test test/storage_rest_io_env_test.dart');
}
