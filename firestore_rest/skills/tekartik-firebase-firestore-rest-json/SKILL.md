---
name: tekartik-firebase-firestore-rest-json
description: >-
  Use when converting Firestore documents to or from the Firestore v1 REST
  wire json (the typed `stringValue` / `integerValue` / `timestampValue` /
  `mapValue` / `arrayValue` / `referenceValue` / `geoPointValue` /
  `bytesValue` envelopes) with package:tekartik_firebase_firestore_rest/snapshot.dart:
  snapshotToJson, documentDataToJson, documentDataValueToJson and
  documentDataFromSnapshot. Read it when writing REST fixtures or a golden
  file, exporting documents, debugging what the REST API actually sends, or
  handling Blob, GeoPoint, Timestamp and DocumentReference values over REST.
---

# tekartik_firebase_firestore_rest: REST document json

The Firestore REST API does not send plain json: every value is wrapped in a
typed envelope and every document carries its full
`projects/<id>/databases/(default)/documents/<path>` name.
`package:tekartik_firebase_firestore_rest/snapshot.dart` converts the generic
`DocumentSnapshot` / `DocumentData` objects to that shape.

## Guidelines

* `import 'package:tekartik_firebase_firestore_rest/snapshot.dart';`. Unlike
  `firestore_rest.dart` it does **not** re-export the firestore types: import
  `package:tekartik_firebase_firestore/firestore.dart` (or
  `firestore_rest.dart`) as well for `DocumentSnapshot`, `DocumentData`,
  `Blob`, `GeoPoint`, `Timestamp`.
* Every function takes the `App` first: it is only used to build the
  `projects/<projectId>/databases/(default)/documents` prefix of document
  names and reference values, so the app's `options.projectId` must be set.
  The database is always `(default)`.
* `snapshotToJson(app, snapshot)` returns the full REST document
  (`name`, `fields`, `createTime`, `updateTime` as ISO-8601 strings) or
  `null` when the snapshot does not exist — always null-check it.
* `documentDataToJson(app, data, {map})` returns `{'fields': {...}}`, adding
  to `map` when given (that is how `snapshotToJson` merges `fields` into the
  document). Pass a `DocumentData`, e.g. `DocumentData(snapshot.data)`.
* `documentDataValueToJson(app, value)` converts one value. Supported:
  `String` → `stringValue`, `int` → `integerValue` (**as a string**, the REST
  encoding), other `num` → `doubleValue`, `bool` → `booleanValue`, `List` →
  `arrayValue.values`, `Map` and `DocumentData` → `mapValue.fields`,
  `DateTime` (converted to UTC) and `Timestamp` → `timestampValue`,
  `DocumentReference` → `referenceValue` (absolute name), `Blob` →
  `bytesValue` (base64), `GeoPoint` → `geoPointValue` with `latitude` /
  `longitude`. Anything else — including `FieldValue.serverTimestamp`,
  `FieldValue.delete`, `null` and vector values — throws an `ArgumentError`.
  Strip or replace sentinels before converting.
* Map keys must be `String`: a `Map` with other key types throws when cast.
* These are one-way helpers: there is no public `jsonToSnapshot`. To read REST
  json back, go through the normal `firestoreServiceRest` API, or
  `documentDataFromSnapshot(snapshot)`, which just returns
  `DocumentData(snapshot.data)` (or `null` when the document does not exist).
* Useful for fixtures, golden files, diffing what the emulator returns, or
  pre-seeding a REST endpoint by hand — not a serialization format for your
  own storage. For plain json use the generic firestore
  `DocumentData` / `cv` utilities instead.
* Integers are strings on the wire: comparing generated json to a REST
  response is only meaningful if you keep that convention
  (`{'integerValue': '23'}`, not `23`).

## Examples

### Export a document as the REST API would send it

```dart
import 'dart:convert';

import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_rest/snapshot.dart';

/// Null when the document does not exist.
Future<String?> exportDocument(App app, DocumentReference ref) async {
  var snapshot = await ref.get();
  var map = snapshotToJson(app, snapshot);
  if (map == null) {
    return null;
  }
  // {"name": "projects/<id>/databases/(default)/documents/<path>",
  //  "fields": {...}, "createTime": ..., "updateTime": ...}
  return const JsonEncoder.withIndent('  ').convert(map);
}
```

### Build a `fields` payload from a map

```dart
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_rest/snapshot.dart';

/// {'fields': {'name': {'stringValue': 'Alice'},
///             'age': {'integerValue': '23'}, ...}}
Map<String, Object?> restFields(App app, Map<String, Object?> data) {
  return documentDataToJson(app, DocumentData(data));
}

/// Sentinels have no REST value: drop them before converting.
Map<String, Object?> withoutSentinels(Map<String, Object?> data) {
  return Map.fromEntries(
    data.entries.where((entry) => entry.value is! FieldValue),
  );
}
```

### Convert the special value types

```dart
import 'dart:typed_data';

import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_rest/snapshot.dart';

void showValues(App app, Firestore firestore) {
  // {'timestampValue': '2019-02-16T17:28:01.792Z'}
  print(documentDataValueToJson(app, Timestamp(1550338081, 792000000)));
  // {'geoPointValue': {'latitude': 23.03, 'longitude': 19.84}}
  print(documentDataValueToJson(app, GeoPoint(23.03, 19.84)));
  // {'bytesValue': 'AQID'}
  print(documentDataValueToJson(app, Blob(Uint8List.fromList([1, 2, 3]))));
  // {'referenceValue': 'projects/<id>/databases/(default)/documents/users/23'}
  print(documentDataValueToJson(app, firestore.doc('users/23')));
  // {'integerValue': '23'} - an int is a string on the wire.
  print(documentDataValueToJson(app, 23));
}
```

### Read a snapshot back as DocumentData

```dart
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_rest/snapshot.dart';

Future<String?> nameOf(DocumentReference ref) async {
  var data = documentDataFromSnapshot(await ref.get());
  return data?.getString('name'); // null when the document is missing
}
```
