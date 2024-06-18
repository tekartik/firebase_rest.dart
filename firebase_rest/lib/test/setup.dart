// ignore: depend_on_referenced_packages
import 'package:tekartik_platform/util/github_util.dart';
import 'package:tekartik_platform_io/context_io.dart';

export 'package:tekartik_firebase_rest/src/test/test_setup.dart' show setup;

bool get runningOnGithub => platformIo.runningOnGithub;

/// stable
/// ubuntu-latest
bool isGithubActionsUbuntuAndDartStable() {
  return platformIo.environment['TEKARTIK_GITHUB_ACTIONS_DART'] == 'stable' &&
      (platformIo.environment['TEKARTIK_GITHUB_ACTIONS_OS']
              ?.startsWith('ubuntu') ??
          false);
}

final githubActionsPrefix =
    'ga_${platformIo.environment['TEKARTIK_GITHUB_ACTIONS_DART']}_${platformIo.environment['TEKARTIK_GITHUB_ACTIONS_OS']?.split('-').first}';
