import 'package:process_run/shell.dart';
import 'package:test/test.dart';

import 'no_auth_firestore.dart';

void main() {
  var env = ShellEnvironment();
  var projectId = env['TEKARTIK_FIRESTORE_REST_NO_AUTH_PROJECT_ID'];
  var rootPath = env['TEKARTIK_FIRESTORE_REST_NO_AUTH_ROOT_PATH'];
  print('projectId: $projectId');
  print('rootPath: $rootPath');
  group('firestore', () {
    test('rootPath', () async {
      var firestore = noAuthFirestoreRest(projectId: projectId);
      await firestore.doc(rootPath!).get();
    });
  }, skip: (projectId == null || rootPath == null));
}
