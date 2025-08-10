import 'package:dev_build/package.dart';
import 'package:dev_build/shell.dart';
import 'package:path/path.dart';

var topDir = '..';

Future<void> main() async {
  shellEnvironment = ShellEnvironment()..vars['GITHUB_ACTIONS'] = 'true';
  for (var dir in [
    'firebase_rest',
    'auth_rest',
    'storage_rest',
    'firestore_rest',
  ]) {
    await packageRunCi(join(topDir, dir));
  }
}
