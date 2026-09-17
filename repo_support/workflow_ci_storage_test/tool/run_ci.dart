import 'package:path/path.dart';
import 'package:process_run/shell.dart';

var topDir = join('..', '..');

/// Set by this script only, so that the env test (which needs the private
/// service account) is run here and not in the regular run_ci workflow.
const githubActionsEnvTestEnvKey = 'TEKARTIK_GITHUB_ACTIONS_ENV_TEST';

Future<void> main() async {
  var shell = Shell(
    workingDirectory: join(topDir, 'storage_rest'),
    environment: ShellEnvironment()..vars[githubActionsEnvTestEnvKey] = 'true',
  );
  await shell.run('dart test test/storage_rest_io_env_test.dart');
}
