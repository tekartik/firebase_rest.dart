// ignore_for_file: avoid_print

@TestOn('vm')
library;

import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_rest/test/setup.dart';

import 'package:tekartik_firebase_test/firebase_test.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  var context = await firebaseRestSetup(useEnv: true);

  if (context == null) {
    test('no env setup available', () {});
  } else {
    if (shouldSkipEnvTestOnGithub()) {
      test('Skip env test on github', () {
        print('githubActionsPrefix: $githubActionsPrefix');
        print('Env test only run by the dedicated env test workflow (linux)');
      });
      return;
    }
    group('rest', () {
      test('setup', () {
        print('Using firebase:');
        print('projectId: ${context.options!.projectId}');
      });
      // there is no name on node
      runFirebaseTests(firebaseRest, options: context.options);
    });
  }
}
