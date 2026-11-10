# tekartik_firebase_storage_rest

Cloud Storage over the Google REST API, in pure Dart: an implementation of
[tekartik_firebase_storage](https://github.com/tekartik/firebase_storage.dart/tree/main/storage)
(buckets, files, upload, download, listing, metadata) on an app of
[tekartik_firebase_rest](../firebase_rest/README.md), plus offline builders
of public download urls (`storage_json.dart`).

Runs on the Dart VM (servers, CLI) and on the web. In a Flutter app prefer
the native `tekartik_firebase_storage_flutter`.

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_storage_rest:
    git:
      url: https://github.com/tekartik/firebase_rest.dart
      path: storage_rest
  tekartik_firebase_rest:
    git:
      url: https://github.com/tekartik/firebase_rest.dart
      path: firebase_rest
```

```dart
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_storage_rest/storage_rest.dart';

/// [serviceAccountJson]: the json of a service account of the project.
Future<void> main(List<String> arguments) async {
  var serviceAccountJson = arguments.first;
  var app = await firebaseRest.initializeAppWithServiceAccountString(
    serviceAccountJson,
    // The storage scope is needed, every call answers 403 otherwise.
    scopes: [...firebaseBaseScopes, firebaseStorageGoogleApisReadWriteScope],
    options: FirebaseAppOptions(storageBucket: 'my-project.appspot.com'),
  );
  var storage = firebaseStorageServiceRest.storage(app);
  var file = storage.bucket().file('tests/hello.txt');
  await file.writeAsString('hello');
  print(await file.readAsString()); // hello

  // Pages of at most 100 files, until there is no next query.
  GetFilesOptions? query = GetFilesOptions(prefix: 'tests/', maxResults: 100);
  while (query != null) {
    var response = await storage.bucket().getFiles(query);
    for (var listed in response.files) {
      print(listed.name);
    }
    query = response.nextQuery;
  }

  await file.delete();
  await app.delete();
}
```

## When to use what

| Need | Use |
|---|---|
| files of a bucket from a server or a tool | `firebaseStorageServiceRest.storage(app)` on a service account app |
| storage from any authenticated http client, no app | `FirebaseStorageRest.fromAuthClient(authClient: client)` |
| the local storage emulator | `await storage.useStorageEmulator('localhost', 9199)` before any call |
| a public download url, no network | `UnauthenticatedStorageApi(client: null).getDownloadUrl(...)` (`storage_json.dart`) |

## Pitfalls

* Uploads are made publicly readable (`predefinedAcl: 'publicRead'`): do not
  upload private data with it. A bucket with uniform bucket-level access
  refuses such uploads.
* `getFiles` returns one page (`maxResults` files, 1000 by default) and a
  `nextQuery` while there are more: loop until it is null (`autoPaginate` is
  ignored).
* `getDownloadUrl()` gives an url without token: it works only for objects
  the rules (or the ACL) let anyone read.
* `FileMetadata.dateUpdated` is the creation time of the object.
* `storage.ref('a/path')` needs the `storageBucket` app option; a
  `gs://bucket/path` link does not.

The skills have more examples:
[setup](skills/tekartik-firebase-storage-rest-setup/SKILL.md) (emulator,
shared tests, standalone client) and
[download urls](skills/tekartik-firebase-storage-rest-download-urls/SKILL.md).
