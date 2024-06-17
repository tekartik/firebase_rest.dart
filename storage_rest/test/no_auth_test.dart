import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

import 'no_auth_storage_rest.dart';

var noAuthProjectIdKey = 'TEKARTIK_STORAGE_REST_NO_AUTH_PROJECT_ID';
var noAuthBucketKey = 'TEKARTIK_STORAGE_REST_NO_AUTH_BUCKET';
var noAuthRootPathKey = 'TEKARTIK_STORAGE_REST_NO_AUTH_ROOT_PATH';

void main() {
  var env = ShellEnvironment();
  var projectId = env[noAuthProjectIdKey];
  var rootPath = env[noAuthRootPathKey];
  var bucketName = env[noAuthBucketKey];
  print('projectId: $projectId');
  print('bucket: $bucketName');
  print('rootPath: $rootPath');
  group('firestore', () {
    /// For this test specify both env variable and create a new document at rootPath
    test('rootPath', () async {
      var storage = noAuthStorageRest(projectId: projectId);
      var bucket = storage.bucket(bucketName);
      // var response = await bucket.getFiles(GetFilesOptions(maxResults: 2));
      var path = url.join(rootPath!, 'simple_file.txt');
      var content = await bucket.file(path).readAsString();
      expect(content, isNotNull);
      //devPrint(content);
      // No!
      /*
      await bucket
          .file(path)
          .writeAsString(content);
      run(
          firebase: firebase,
          storageService: storageServiceRest,
          options: context.options,
          storageOptions: storageOptionsFromEnv);

       */
    });
  }, skip: (projectId == null || rootPath == null || bucketName == null));
}
