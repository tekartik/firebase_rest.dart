import 'package:process_run/shell.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';

var _env = shellEnvironment;
TestStorageOptions? _storageOptionsFromEnv;

TestStorageOptions getStorageOptionsFromEnv(Map<String, String> env) {
  var storageBucket = env['firebaseStorageTestBucket'];
  var rootPath =
      env['TEKARTIK_FIREBASE_STORAGE_REST_TEST_ROOT_PATH'] ??
      env['firebaseStorageTestRootPath'];
  return TestStorageOptions(bucket: storageBucket, rootPath: rootPath);
}

/// Get storage option from env on node, dummy on io
TestStorageOptions get storageOptionsFromEnv =>
    _storageOptionsFromEnv ??= () {
      return getStorageOptionsFromEnv(_env);
    }();
