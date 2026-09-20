---
name: tekartik-firebase-firestore-rest-setup
description: >-
  Use when reading or writing Cloud Firestore from pure Dart (VM, server, CLI,
  web) over the v1 REST API with tekartik_firebase_firestore_rest:
  firestoreServiceRest, FirestoreServiceRest, FirestoreRest,
  useFirestoreEmulator(host, port, owner:),
  firestoreGoogleApisAuthDatastoreScope /
  firestoreGoogleApisAuthCloudPlatformScope, debugFirestoreRest, and the
  supportsTransaction / supportsTrackChanges / supportsFieldValueArray
  capability flags. Read it before expecting onSnapshot, documentChanges or a
  transaction to work over REST, when wiring firestore on a FirebaseAppRest,
  or when running the shared tekartik_firebase_firestore_test suites
  (runFirestoreTests, runFirestoreAppTests) against REST.
---

# tekartik_firebase_firestore_rest: Firestore over the v1 REST API

`tekartik_firebase_firestore_rest` implements the generic
`tekartik_firebase_firestore` API (`Firestore`, `CollectionReference`,
`DocumentReference`, `Query`, `WriteBatch`, `Transaction`) on top of the
`googleapis` Firestore v1 REST client. It needs a `FirebaseAppRest` from
`tekartik_firebase_rest`; document/query semantics are the generic ones, only
setup and the missing pieces are specific.

## Guidelines

* Not on pub.dev. Git dependency, with the app package:
  ```yaml
  dependencies:
    tekartik_firebase_firestore_rest:
      git:
        url: https://github.com/tekartik/firebase_rest.dart
        path: firestore_rest
      version: '>=0.8.6'
    tekartik_firebase_rest:
      git:
        url: https://github.com/tekartik/firebase_rest.dart
        path: firebase_rest
  ```
* `package:tekartik_firebase_firestore_rest/firestore_rest.dart` re-exports
  `package:tekartik_firebase_firestore/firestore.dart`, so `Firestore`,
  `DocumentSnapshot`, `Timestamp`, `FieldValue`, `Blob`, `GeoPoint` and the
  query types come with the single import.
* Get the instance with `firestoreServiceRest.firestore(app)` where `app` is a
  `FirebaseAppRest`; the result is a `FirestoreRest`. `firestoreServiceRest`
  is a top-level variable of type `FirestoreServiceRest` (it can be replaced
  in tests). The instance is cached per app.
* Scopes: initialize the app with `firestoreGoogleApisAuthDatastoreScope`
  (`https://www.googleapis.com/auth/datastore`), usually together with
  `firebaseGoogleApisUserEmailScope` from `tekartik_firebase_rest`.
  `firestoreGoogleApisAuthCloudPlatformScope` is the broader alternative.
  `googleApisAuthDatastoreScopre` and `googleApisAuthCloudPlatformScope` are
  deprecated spellings, do not use them.
* **No realtime.** `DocumentReference.onSnapshot()` and `Query.onSnapshot()`
  throw `UnsupportedError`, and `QuerySnapshot.documentChanges` throws too
  (`supportsTrackChanges` is `false`). For listeners use the sibling
  `tekartik_firebase_firestore_grpc_rest`, which wraps this implementation
  and adds a gRPC `Listen` stream. Poll with `get()` otherwise.
* `firestore.supportsTransaction` is decided per app, and only once auth is
  ready (`await auth.onCurrentUser.first`): `true` with service-account
  (admin) credentials or an OAuth2 (Google) sign-in, `false` with api-key-only
  access and `false` for an email/password REST user. Check it before calling
  `runTransaction`; `batch()` always works.
* Other capability flags on the service: `supportsQuerySelect`,
  `supportsListCollections`, `supportsAggregateQueries`, `supportsBlobs`,
  `supportsTimestamps`, `supportsDocumentSnapshotTime` are `true`;
  `supportsFieldValueArray` (`FieldValue.arrayUnion`/`arrayRemove`),
  `supportsQuerySnapshotCursor` and `supportsVectorValue` are `false`. Guard
  generic code on these instead of catching `UnsupportedError`.
* `where` maps to the REST field filters `EQUAL`, `LESS_THAN`,
  `LESS_THAN_OR_EQUAL`, `GREATER_THAN`, `GREATER_THAN_OR_EQUAL`,
  `ARRAY_CONTAINS`, `ARRAY_CONTAINS_ANY`, `IN` and the unary `IS_NULL`
  (`isNull: true`). Anything else throws `UnsupportedError`. Remember the
  Firestore rule that an inequality field must come first in `orderBy`.
* Emulator: `await firestore.useFirestoreEmulator('localhost', 8080)` right
  after getting the instance (it drops the cached api client). Pass
  `owner: true` to send `Authorization: Bearer owner` on every request, which
  bypasses the security rules and is required for metadata calls such as
  `listCollectionIds` — emulator only, never against production.
* Unauthenticated access (public rules or emulator) works: an app built with
  `AppOptionsRest(client: Client())..projectId = ...` is enough, no
  credentials needed.
* Set `debugFirestoreRest = true` to log every REST call and payload while
  debugging.
* Shared suites (dev dependency `tekartik_firebase_firestore_test`):
  `runFirestoreTests(firebase: firebaseRest, firestoreService:
  firestoreServiceRest, options:, testContext: FirestoreTestContext())` and
  `runFirestoreAppTests(app:, firestoreService:, testContext:)`. Set
  `skipConcurrentTransactionTests = true` for REST, and allow for read delay
  with `FirestoreTestContext()..allowedDelayInReadMs = 3000`.
* Use `tekartik_firebase_firestore_sembast` (in-memory) rather than mocks when
  you only need a Firestore for a unit test.

## Examples

### Firestore from a service account, read and write

```dart
import 'dart:io';

import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<Firestore> initFirestore(String serviceAccountPath) async {
  var app = await firebaseRest.initializeAppWithServiceAccountString(
    File(serviceAccountPath).readAsStringSync(),
    scopes: [
      firestoreGoogleApisAuthDatastoreScope,
      firebaseGoogleApisUserEmailScope,
    ],
  );
  return firestoreServiceRest.firestore(app as FirebaseAppRest);
}

Future<void> readWrite(Firestore firestore) async {
  var ref = firestore.collection('users').doc('user_1');
  await ref.set({'name': 'Alice', 'createdAt': FieldValue.serverTimestamp});
  var snapshot = await ref.get();
  if (snapshot.exists) {
    print(snapshot.data);
  }
}
```

### Unauthenticated app against the emulator, as owner

```dart
import 'package:http/http.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<FirestoreRest> emulatorFirestore(String projectId) async {
  var app =
      firebaseRest.initializeApp(
            name: 'emulator',
            options: AppOptionsRest(client: Client())..projectId = projectId,
          )
          as FirebaseAppRest;
  var firestore = firestoreServiceRest.firestore(app);
  // owner: true bypasses the rules, needed for listCollections. Emulator only.
  await firestore.useFirestoreEmulator('localhost', 8080, owner: true);
  return firestore;
}
```

### Query, batch, and the transaction guard

```dart
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';

Future<List<DocumentSnapshot>> cheapProducts(Firestore firestore) async {
  var snapshot = await firestore
      .collection('products')
      .where('price', isLessThan: 50)
      .orderBy('price')
      .limit(10)
      .get();
  return snapshot.docs;
}

Future<void> writeTwo(Firestore firestore) async {
  var batch = firestore.batch();
  batch.set(firestore.collection('counters').doc('c1'), {'count': 10});
  batch.update(firestore.collection('counters').doc('c2'), {'count': 20});
  await batch.commit(); // always available, unlike runTransaction
}

Future<void> increment(Firestore firestore, String path) async {
  if (!firestore.supportsTransaction) {
    // api key only, or an email/password REST user: no transaction over REST.
    throw UnsupportedError('transactions need admin or oauth2 credentials');
  }
  await firestore.runTransaction((txn) async {
    var ref = firestore.doc(path);
    var snapshot = await txn.get(ref);
    txn.set(ref, {'count': ((snapshot.data['count'] as int?) ?? 0) + 1});
  });
}
```

### Polling instead of onSnapshot

```dart
import 'dart:async';

import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';

/// REST has no listener: `ref.onSnapshot()` throws UnsupportedError. Either
/// poll like this, or use tekartik_firebase_firestore_grpc_rest.
Stream<DocumentSnapshot> poll(
  DocumentReference ref, {
  Duration period = const Duration(seconds: 5),
}) async* {
  while (true) {
    yield await ref.get();
    await Future<void>.delayed(period);
  }
}
```

### Running the shared firestore suite over REST

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_rest/firebase_rest_setup.dart';
import 'package:test/test.dart';

Future<void> main() async {
  skipConcurrentTransactionTests = true;
  var context = await firebaseRestSetupContext(
    scopes: [
      firestoreGoogleApisAuthDatastoreScope,
      firebaseGoogleApisUserEmailScope,
    ],
  );
  group('rest_io', () {
    if (context != null) {
      runFirestoreTests(
        firebase: firebaseRest,
        firestoreService: firestoreServiceRest,
        testContext: FirestoreTestContext()..allowedDelayInReadMs = 3000,
        options: context.options,
      );
    }
  }, skip: context == null);
}
```
