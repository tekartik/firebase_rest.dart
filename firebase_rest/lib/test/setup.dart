import 'dart:io' as io;

// ignore: depend_on_referenced_packages
import 'package:tekartik_platform/util/github_util.dart';
import 'package:tekartik_platform_io/context_io.dart';

export 'package:tekartik_firebase_rest/src/test/test_setup.dart' show setup;

/// True if running on github
bool get runningOnGithub => platformIo.runningOnGithub;

/// Github actions prefix
final githubActionsPrefix = 'ga_${io.Platform.operatingSystem}';

/// Env variable set by the dedicated env test workflows
/// (`run_ci_<name>_test.yml`) through
/// `repo_support/workflow_ci_<name>_test/tool/run_ci.dart`, which uses
/// `firebaseGithubActionEnvTestShell` (`package:tekartik_firebase_test/ci_shell_io.dart`).
///
/// It is not set by the regular run_ci.yml workflow.
const githubActionsEnvTestEnvKey = 'TEKARTIK_GITHUB_ACTIONS_ENV_TEST';

/// True if the env tests (needing the private service account) are explicitly
/// requested, i.e. when running the dedicated env test workflow.
bool isGithubActionsEnvTest() =>
    platformIo.environment[githubActionsEnvTestEnvKey] == 'true';

/// True if the env tests (needing the private service account) must be skipped.
///
/// On github they are only run by the dedicated env test workflow
/// (`run_ci_<name>_test.yml`), on linux. Outside of github they are always run
/// (when the env is available).
bool shouldSkipEnvTestOnGithub() =>
    runningOnGithub && (!isGithubActionsEnvTest() || !io.Platform.isLinux);
