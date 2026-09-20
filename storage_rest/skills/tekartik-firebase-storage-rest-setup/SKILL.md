---
name: tekartik-firebase-storage-rest-setup
description: >-
  Use when reading or writing Cloud Storage objects from pure Dart (VM, server,
  web, CLI) over the Google Cloud Storage v1 REST API with
  tekartik_firebase_storage_rest: firebaseStorageServiceRest,
  firebaseStorageServiceRest.storage(app) on a firebaseRest app,
  FirebaseStorageRest, FirebaseStorageRest.fromAuthClient,
  firebaseStorageGoogleApisReadWriteScope, useStorageEmulator, the compat
  aliases storageServiceRest / StorageServiceRest / StorageRest, bucket.file /
  getFiles, file.upload / writeAsString / readAsBytes / getMetadata / delete,
  and running the shared runStorageTests suite against a real project or the
  firebase storage emulator.
---

# tekartik_firebase_storage_rest: Cloud Storage over REST

`tekartik_firebase_storage_rest` implements the `tekartik_firebase_storage`
abstractions (`FirebaseStorageService`, `Storage`, `Bucket`, `File`,
`FileMetadata`, `GetFilesOptions`) on top of the `googleapis` Cloud Storage v1
API and the authenticated `package:http` client carried by a
`tekartik_firebase_rest` app. No native SDK, no `dart:io` in the public
libraries: it runs on the VM, on a server and in the browser. The public
download url side of the package (unauthenticated `firebasestorage.googleapis.com`
json endpoint) is covered by [tekartik-firebase-storage-rest-download-urls](../tekartik-firebase-storage-rest-download-urls/SKILL.md).

## Guidelines

* Dependency (git, not on pub.dev — the README still says "not supported yet",
  ignore it, the implementation is complete and tested against a real project
  and the storage emulator):
  ```yaml
  dependencies:
    tekartik_firebase_storage_rest:
      git:
        url: https://github.com/tekartik/firebase_rest.dart
        path: storage_rest
      version: '>=0.8.4'
    tekartik_firebase_rest:
      git:
        url: https://github.com/tekartik/firebase_rest.dart
        path: firebase_rest
      version: '>=0.8.4'
  ```
  It brings `tekartik_firebase_storage` (the API) and `googleapis`.
* Import `package:tekartik_firebase_storage_rest/storage_rest.dart`: it
  re-exports `package:tekartik_firebase_storage/storage.dart` (and through it
  `tekartik_firebase`) and adds `firebaseStorageServiceRest`,
  `FirebaseStorageServiceRest`, `FirebaseStorageRest` and
  `firebaseStorageGoogleApisReadWriteScope`. `storageServiceRest`,
  `StorageServiceRest`, `StorageRest` and `storageGoogleApisReadWriteScope`
  are compat aliases of the same things — prefer the `firebaseStorage*` names.
  Never import `src/...` (the embedded `src/storage/v1.dart` is just a
  re-export of `package:googleapis/storage/v1.dart`).
* The app comes from `tekartik_firebase_rest` (see the
  `tekartik-firebase-rest-setup` skill): initialize it with the storage scope,
  `firebaseStorageGoogleApisReadWriteScope`
  (`https://www.googleapis.com/auth/devstorage.read_write`), on top of
  `firebaseGoogleApisUserEmailScope` / `firebaseBaseScopes`. Without that
  scope every object call fails with a 403.
* `firebaseStorageServiceRest.storage(app)` returns the `Storage` of a
  `FirebaseAppRest`, cached per app and registered on it (`app.storage()`
  gives it back). It asserts the app is a `FirebaseAppRest`. `storage.app`,
  `storage.service` walk back; `storage.dispose()` (or `app.delete()`)
  releases it.
* Without an app: `FirebaseStorageRest.fromAuthClient(authClient: client)`
  builds a standalone `Storage` from any authenticated `package:http`
  `Client` (a `googleapis_auth` client, a token client...). It has no app
  options, so always name the bucket explicitly and do not call `ref()` on it.
* `storage.bucket()` uses `app.options.storageBucket`, falling back to
  `<projectId>.appspot.com`; `storage.bucket(name)` targets a named bucket,
  never with a `gs://` prefix. `bucket.exists()` maps a 404 to `false`,
  `bucket.file(path)` is purely local (bucket relative path, no leading `/`).
  There is no `bucket.create()` here: create buckets in the console.
* Writing: `file.upload(bytes, options: StorageUploadFileOptions(contentType:
  ...))`, `writeAsBytes(bytes)`, `writeAsString(text)` (UTF-8) or the legacy
  `save(content)` (accepts a `Uint8List` or a `String`). When no content type
  is given it is guessed from the file name with
  `firebaseStorageContentTypeFromFilename` (null for an unknown extension).
  **Uploads use `predefinedAcl: 'publicRead'`**: an object written here is
  world readable unless the bucket enforces uniform bucket-level access —
  check that before uploading private data.
* Reading: `readAsBytes()` / `readAsString()` (`download()` is the same
  thing), `exists()` (404 mapped to `false`), `delete()`, `getMetadata()`
  (`size`, `md5Hash`, `contentType` and `dateUpdated`, which is the object
  `timeCreated`, not its last update). `file.metadata` is a cache filled only
  on files returned by `getFiles()`, and null on a `bucket.file(path)`
  reference.
* Listing: `bucket.getFiles(GetFilesOptions(prefix: 'dir/', pageToken: ...))`
  returns a `GetFilesResponse` with `files` (each with its metadata) and a
  `nextQuery` to pass back while it is not null. Only `prefix` and `pageToken`
  reach the REST call: `maxResults` is not sent to the server (it only stops
  the paging loop) and `autoPaginate` is carried over untouched, so filter or
  truncate on your side.
* Anything but a 404 on `exists()` is rethrown as the `googleapis`
  `DetailedApiRequestError` (`status`, `message`), which this package does not
  re-export: probe with `exists()` rather than catching, or add a direct
  `googleapis` dependency to `import 'package:googleapis/storage/v1.dart'
  show DetailedApiRequestError;`.
* Storage emulator: `await (storage as FirebaseStorageRest)
  .useStorageEmulator('localhost', 9199)` right after creating the storage and
  **before** any call (it swaps the api root url and drops the cached client).
  Uploads then take a manual resumable upload path, because the emulator does
  not parse the multipart bodies the googleapis client normally sends. Use an
  app with dummy credentials (`AppOptionsRest(client: Client())`, or
  `FirebaseAppOptions(projectId: ..., apiKey: 'dummy', storageBucket: ...)`),
  never production credentials.
* Tests: the shared suite is `runStorageTests(firebase: firebaseRest,
  storageService: firebaseStorageServiceRest, options: context.options,
  storageOptions: TestStorageOptions(bucket: ..., rootPath: ...))` from
  `package:tekartik_firebase_storage_test/storage_test.dart` (it initializes
  the app and deletes it in `tearDownAll`); `runStorageAppTests(app, ...)`
  takes an existing app instead. Against a real project the credentials come
  from the `tekartik_firebase_rest` setup helpers (`firebaseRestSetupContext`,
  or `setup` from `package:tekartik_firebase_rest/test/setup.dart` with
  `useEnv: true`) with the storage scope added, plus a dedicated
  `TEKARTIK_FIREBASE_STORAGE_REST_TEST_ROOT_PATH` prefix; guard them with
  `shouldSkipEnvTestOnGithub()`. Never point `rootPath` at real data: the
  suite creates and deletes objects under it.
* Emulator tests use `FirebaseEmulatorService(path: 'emulator')` from
  `tekartik_firebase_emulator` (`FirebaseEmulatorOptions(projectId: ...,
  onlyStorage: true)`), `dart_test.yaml` with `concurrency: 1` and a generous
  `timeout`. `runStorageTests` registers its groups synchronously, so the
  `useStorageEmulator` call can follow it in `main` before the runner starts.

## Examples

### Service account app, upload, read back, delete

```dart
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_storage_rest/storage_rest.dart';

/// [serviceAccountJson] is the raw service account json.
Future<void> run(String serviceAccountJson) async {
  var app = await firebaseRest.initializeAppWithServiceAccountString(
    serviceAccountJson,
    scopes: [
      ...firebaseBaseScopes,
      firebaseStorageGoogleApisReadWriteScope,
    ],
    options: FirebaseAppOptions(storageBucket: 'my-project.appspot.com'),
  );
  var storage = firebaseStorageServiceRest.storage(app);

  var file = storage.bucket().file('tests/hello.txt');
  await file.writeAsString('hello');
  print(await file.readAsString());

  var metadata = await file.getMetadata();
  print('${metadata.size} bytes, ${metadata.contentType}, ${metadata.md5Hash}');

  await file.delete();
  await app.delete();
}
```

### Upload bytes with an explicit content type

```dart
import 'dart:typed_data';

import 'package:tekartik_firebase_storage_rest/storage_rest.dart';

Future<void> uploadImage(Bucket bucket, String path, Uint8List bytes) async {
  // Without options the content type is guessed from the file name.
  await bucket
      .file(path)
      .upload(
        bytes,
        options: StorageUploadFileOptions(contentType: 'image/png'),
      );
}
```

### Listing a prefix page by page

```dart
import 'package:tekartik_firebase_storage_rest/storage_rest.dart';

Future<List<String>> listPaths(Bucket bucket, String prefix) async {
  var paths = <String>[];
  GetFilesOptions? query = GetFilesOptions(prefix: prefix);
  while (query != null) {
    var response = await bucket.getFiles(query);
    for (var file in response.files) {
      // metadata is filled by getFiles here.
      paths.add('${file.name} (${file.metadata?.size ?? -1})');
    }
    query = response.nextQuery;
  }
  return paths;
}
```

### Standalone storage from an authenticated client

```dart
import 'package:http/http.dart';
import 'package:tekartik_firebase_storage_rest/storage_rest.dart';

/// [authClient] is an authenticated client (googleapis_auth, access token...)
/// with the devstorage.read_write scope. No app, so name the bucket.
Future<String> readText(Client authClient, String bucket, String path) async {
  var storage = FirebaseStorageRest.fromAuthClient(authClient: authClient);
  try {
    return await storage.bucket(bucket).file(path).readAsString();
  } finally {
    storage.dispose();
  }
}
```

### Against the local storage emulator

```dart
import 'package:http/http.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_storage_rest/storage_rest.dart';

/// Requires `firebase emulators:start --only storage` (port 9199).
Future<Storage> emulatorStorage({
  required String projectId,
  required String storageBucket,
}) async {
  var app = firebaseRest.initializeApp(
    options: AppOptionsRest(client: Client(), storageBucket: storageBucket)
      ..projectId = projectId,
    name: 'emulator',
  );
  var storage = firebaseStorageServiceRest.storage(app) as FirebaseStorageRest;
  // Immediately, before any other storage call.
  await storage.useStorageEmulator('localhost', 9199);
  return storage;
}
```

### Shared storage suite against the emulator

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_storage_rest/storage_rest.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

var _emulatorService = FirebaseEmulatorService(path: 'emulator');

Future<void> main() async {
  if (!await _emulatorService.isSupported()) {
    test('not_supported', () {}, skip: 'firebase emulator is not supported');
    return;
  }
  var projectId = await _emulatorService.getProjectId();
  var storageBucket = '$projectId.appspot.com';
  late FirebaseEmulator emulator;

  group('storage_rest_emulator', () {
    setUpAll(() async {
      emulator = await _emulatorService.start(
        options: FirebaseEmulatorOptions(
          projectId: projectId,
          onlyStorage: true,
        ),
      );
    });
    tearDownAll(() => emulator.stop());

    runStorageTests(
      firebase: firebaseRest,
      storageService: firebaseStorageServiceRest,
      options: FirebaseAppOptions(
        projectId: projectId,
        apiKey: 'dummy',
        storageBucket: storageBucket,
      ),
      storageOptions: TestStorageOptions(
        bucket: storageBucket,
        skipDefaultBucketExists: true,
      ),
    );
  }, timeout: const Timeout(Duration(minutes: 5)));

  // The groups above only registered: the storage instance can still be
  // pointed at the emulator before the runner starts.
  var storage =
      firebaseStorageServiceRest.storage(firebaseRest.app())
          as FirebaseStorageRest;
  await storage.useStorageEmulator('localhost', 9199);
}
```

## Common mistakes

* Initializing the app without `firebaseStorageGoogleApisReadWriteScope`: the
  app works, every object call returns 403.
* Uploading private data without checking the bucket access model: uploads ask
  for `publicRead`.
* Calling `useStorageEmulator` after a first storage call, or against
  production credentials.
* Expecting `GetFilesOptions.maxResults` to limit the REST call: only `prefix`
  and `pageToken` are sent.
* Stopping a `getFiles` loop on an empty page instead of a null `nextQuery`.
* Reading `file.metadata` on a `bucket.file(path)` reference (null) instead of
  awaiting `getMetadata()`, or reading `dateUpdated` as a modification time
  (it is the creation time).
* Passing a memory / node / flutter app to `firebaseStorageServiceRest`, or a
  `gs://` prefixed name to `storage.bucket(...)`.
* Calling `ref()` on a `FirebaseStorageRest.fromAuthClient` storage (no app
  options, it throws).
