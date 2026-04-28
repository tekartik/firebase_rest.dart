import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_firebase_storage/utils/link.dart';
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
  test('getDownloadUrl', () async {
    var storage = noAuthStorageRest(projectId: 'test1');
    var bucket = 'bucket1';
    var path = 'path1/path2/file.txt';
    var downloadUrl = await storage
        .ref(StorageFileRef(bucket, path).toLink().toString())
        .getDownloadUrl();
    expect(
      downloadUrl,
      'https://firebasestorage.googleapis.com/v0/b/bucket1/o/path1%2Fpath2%2Ffile.txt?alt=media',
    );

    storage.dispose();
  });
  group('storage', () {
    /// For this test specify both env variable and create a new document at rootPath
    test('rootPath', () async {
      var storage = noAuthStorageRest(projectId: projectId);
      var bucket = storage.bucket(bucketName);
      // var response = await bucket.getFiles(GetFilesOptions(maxResults: 2));
      var path = url.join(rootPath!, 'simple_file.txt');
      var content = await bucket.file(path).readAsString();
      expect(content, isNotNull);
      if (bucketName != null) {
        var downloadUrl = await storage
            .ref(StorageFileRef(bucketName, path).toLink().toString())
            .getDownloadUrl();
        expect(http.read(Uri.parse(downloadUrl)), content);
      }
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
      storage.dispose();
    });
  }, skip: (projectId == null || rootPath == null || bucketName == null));
}
