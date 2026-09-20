---
name: tekartik-firebase-storage-rest-download-urls
description: >-
  Use when building public Firebase Storage download urls or listing objects
  without credentials from Dart with the storage_json.dart library of
  tekartik_firebase_storage_rest: UnauthenticatedStorageApi (storageBucket,
  list, getFileUrl, getMediaUrl, getDownloadUrl, getInfo), GsReference,
  GsReferenceListResponse, the firebasestorage.googleapis.com/v0 endpoint, and
  storage.ref('gs://bucket/path').getDownloadUrl() on a REST storage instance.
---

# Public download urls (tekartik_firebase_storage_rest, storage_json.dart)

`package:tekartik_firebase_storage_rest/storage_json.dart` is the second,
credential-free half of the package: it talks to the Firebase Storage json
endpoint (`https://firebasestorage.googleapis.com/v0/b/<bucket>/o/...`), the
one that serves public download urls, rather than to the authenticated Cloud
Storage v1 API used by [tekartik-firebase-storage-rest-setup](../tekartik-firebase-storage-rest-setup/SKILL.md).
Url building needs no client and no network at all.

## Guidelines

* Same package and git dependency as the main skill
  (`url: https://github.com/tekartik/firebase_rest.dart`, `path:
  storage_rest`). Import
  `package:tekartik_firebase_storage_rest/storage_json.dart`: it re-exports
  `package:tekartik_firebase_storage/storage.dart` (so `AppOptions`,
  `Storage`, `Bucket`, `File` come with it) and adds
  `UnauthenticatedStorageApi`, `GsReference` and `GsReferenceListResponse`.
  `StorageFileRef` lives in
  `package:tekartik_firebase_storage/utils/link.dart`, import it too when you
  handle `gs://` links.
* `UnauthenticatedStorageApi({String? storageBucket, AppOptions? appOptions,
  required Client? client})`: `client` is required but **nullable** — pass
  `null` when you only build urls, and a `package:http` `Client` (or the one
  of your app) for `list()` / `getInfo()`, which would otherwise throw on a
  null check. The default bucket comes from `storageBucket`, else from
  `appOptions` (`appOptionsGetStorageBucket`, which reads `storageBucket` and
  falls back to `<projectId>.appspot.com`); reading the `storageBucket` getter
  with neither set throws.
* Url helpers, all synchronous and offline:
  - `getFileUrl(name, {bucket})` →
    `https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<name>` with
    `name` percent encoded as a single component (`a/b.txt` becomes
    `a%2Fb.txt`) — that is the object *info* url (json metadata).
  - `getMediaUrl(name, {bucket})` → the same url plus `?alt=media`, i.e. the
    bytes.
  - `getDownloadUrl(StorageFileRef fileRef)` → `getMediaUrl(fileRef.path,
    bucket: fileRef.bucket)`, the form to use when you already have a
    `gs://bucket/path` link.
  `bucket:` defaults to the api bucket; pass it to target another one.
* These urls are **unauthenticated**: they resolve only for objects that are
  publicly readable (storage rules allowing public read, or a `publicRead`
  ACL — which is what the `storage_rest` upload path sets). A private object
  answers 403; a real Firebase download url with a token is not produced here.
  Never treat such a url as a secret capability.
* From an existing REST storage instance, `storage.ref(path).getDownloadUrl()`
  produces exactly the same url through this api: `path` may be a
  `gs://bucket/path` link (parsed with `StorageFileRef.fromLink`) or a plain
  object path, in which case the app `storageBucket` option must be set (it is
  dereferenced with `!`). `getDownloadUrl()` does no network call, so it works
  on an app without credentials.
* `await api.list({bucket, prefix})` GETs the json endpoint and returns a
  `GsReferenceListResponse`: `items` is a nullable `List<GsReference>`, each
  with `bucket` and `name` (the full object path). There is no paging, no
  `prefixes` parsing and no sorting — it is a debug/read-only helper, use
  `bucket.getFiles(...)` of the main skill for real listings. `prefix` is a
  plain string prefix, usually ending with `/`.
* `await api.getInfo(reference)` GETs the object info url and returns an
  object with `contentType`, `size` and `md5Hash`. Its class (`GsObjectInfo`)
  is not exported: keep it in a `var`, do not try to name the type. Both
  `list()` and `getInfo()` throw on a non-public bucket (403) or an unknown
  object (404), and `getInfo` is documented to sometimes answer 400 — wrap
  them in a `try`.
* `GsReference` and `GsReferenceListResponse` are mutable json holders with a
  `fromMap(Map)` method and a `toDebugMap()`: build one with
  `GsReferenceListResponse()..fromMap(decodedJson)` when you already have the
  json (from a cloud function, a cache...).
* On the web this is often all you need: no service account, no auth client,
  just urls handed to an `<img>` / `Image.network` or to
  `http.read(Uri.parse(url))`.

## Examples

### Build a public download url, no client, no network

```dart
import 'package:tekartik_firebase_storage/utils/link.dart';
import 'package:tekartik_firebase_storage_rest/storage_json.dart';

/// 'gs://my-project.appspot.com/images/logo.png' ->
/// 'https://firebasestorage.googleapis.com/v0/b/my-project.appspot.com/o/images%2Flogo.png?alt=media'
String downloadUrlFromLink(String gsLink) {
  var api = UnauthenticatedStorageApi(client: null);
  return api.getDownloadUrl(StorageFileRef.fromLink(Uri.parse(gsLink)));
}

/// Same, from a bucket relative path and a default bucket.
String downloadUrl(String path) {
  var api = UnauthenticatedStorageApi(
    client: null,
    appOptions: AppOptions(
      projectId: 'my-project',
      storageBucket: 'my-project.appspot.com',
    ),
  );
  return api.getMediaUrl(path);
}
```

### Read a public object with a plain http client

```dart
import 'package:http/http.dart' as http;
import 'package:tekartik_firebase_storage_rest/storage_json.dart';

Future<String> readPublicText(String bucket, String path) async {
  var api = UnauthenticatedStorageApi(client: null, storageBucket: bucket);
  return await http.read(Uri.parse(api.getMediaUrl(path)));
}
```

### List a prefix and get the content type and size of each item

```dart
import 'package:http/http.dart';
import 'package:tekartik_firebase_storage_rest/storage_json.dart';

Future<void> dumpPrefix(String bucket, String prefix) async {
  var client = Client();
  var api = UnauthenticatedStorageApi(client: client, storageBucket: bucket);
  try {
    var response = await api.list(prefix: prefix);
    for (var reference in response.items ?? <GsReference>[]) {
      try {
        // GsObjectInfo is not exported: keep the inferred type.
        var info = await api.getInfo(reference);
        print('${reference.name}: ${info.size} ${info.contentType}');
      } catch (e) {
        print('${reference.name}: info failed $e');
      }
    }
  } finally {
    client.close();
  }
}
```

### Download url from a REST storage instance

```dart
import 'package:http/http.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_storage/utils/link.dart';
import 'package:tekartik_firebase_storage_rest/storage_rest.dart';

/// No credentials needed for the url itself.
Future<String> publicUrl(String projectId, String bucket, String path) async {
  var app = firebaseRest.initializeApp(
    options: AppOptionsRest(client: Client(), storageBucket: bucket)
      ..projectId = projectId,
    name: 'url_only',
  );
  var storage = firebaseStorageServiceRest.storage(app);
  try {
    return await storage
        .ref(StorageFileRef(bucket, path).toLink().toString())
        .getDownloadUrl();
  } finally {
    await app.delete();
  }
}
```

### Parse a json listing you already have

```dart
import 'package:tekartik_firebase_storage_rest/storage_json.dart';

List<String> pathsOf(Map<String, Object?> json) {
  var response = GsReferenceListResponse()..fromMap(json);
  return [for (var item in response.items ?? <GsReference>[]) item.name!];
}
```

## Common mistakes

* Expecting these urls to work on a private object: they carry no token and
  no credentials.
* Calling `list()` or `getInfo()` with `client: null` (it throws on the null
  check), or forgetting to `close()` the client you created.
* Naming the return type of `getInfo` (`GsObjectInfo` is not exported).
* Using `list()` as a real listing API: no paging, no `prefixes`; use
  `bucket.getFiles(...)` from the main storage_rest skill.
* Percent encoding the object path yourself before `getFileUrl` /
  `getMediaUrl`: they already encode it.
* Calling `storage.ref('some/path')` on an app whose `storageBucket` option is
  null (it throws), instead of passing a full `gs://bucket/path` link.
