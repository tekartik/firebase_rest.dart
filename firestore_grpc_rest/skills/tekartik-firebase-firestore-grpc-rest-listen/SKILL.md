---
name: tekartik-firebase-firestore-grpc-rest-listen
description: >-
  Use when a pure Dart (VM) Firestore REST client needs realtime document
  listeners with tekartik_firebase_firestore_grpc_rest: firestoreServiceGrpcRest
  as a drop-in replacement for firestoreServiceRest so DocumentReference
  onSnapshot() works, and the DocumentReferenceGrpcRestExt onGrpcSnapshot()
  extension that opens a raw Firestore v1 gRPC Listen stream. Read it when
  onSnapshot throws UnsupportedError over REST, when a listener must survive a
  sign-in or a token refresh, when handling GrpcError permissionDenied /
  unauthenticated, or when listening against the firestore emulator.
---

# tekartik_firebase_firestore_grpc_rest: REST + gRPC listen

The Firestore REST API has no streaming, so
`tekartik_firebase_firestore_rest` throws `UnsupportedError` from
`onSnapshot()`. This package keeps everything else on REST and adds document
listeners through the Firestore v1 gRPC `Listen` rpc. It is a thin layer over
`tekartik_firebase_firestore_rest`, not a separate implementation.

## Guidelines

* Not on pub.dev. Git dependency; it pulls `tekartik_firebase_firestore_rest`
  and `tekartik_firebase_rest` from the same repo:
  ```yaml
  dependencies:
    tekartik_firebase_firestore_grpc_rest:
      git:
        url: https://github.com/tekartik/firebase_rest.dart
        path: firestore_grpc_rest
    tekartik_firebase_firestore_rest:
      git:
        url: https://github.com/tekartik/firebase_rest.dart
        path: firestore_rest
  ```
* `package:tekartik_firebase_firestore_grpc_rest/firestore_grpc_rest.dart`
  exports exactly two things: `firestoreServiceGrpcRest` and
  `DocumentReferenceGrpcRestExt`. It re-exports nothing, so import
  `package:tekartik_firebase_firestore_rest/firestore_rest.dart` alongside it
  for `Firestore`, `FirestoreRest`, `DocumentSnapshot` and friends.
* **VM only.** `package:grpc`'s `ClientChannel` needs `dart:io` sockets:
  this does not run in a browser. Keep web code on plain
  `firestoreServiceRest` and poll, or use a Flutter/native backend there.
* Drop-in usage: replace `firestoreServiceRest` with
  `firestoreServiceGrpcRest` (also a `FirestoreServiceRest`) when getting the
  instance. Everything else — app setup, scopes, emulator, queries, batches,
  transactions, capability flags — is the REST implementation's, and the
  `tekartik-firebase-firestore-rest-setup` skill applies unchanged. It
  delegates every `supports*` flag to the REST service and only sets
  `supportsRecordTrackChanges` to `true`.
* Only **documents** get a listener. `firestore.doc(path).onSnapshot()` and
  `firestore.collection(c).doc(id).onSnapshot()` work (the collection
  delegates to `firestore.doc`). `Query.onSnapshot()` still throws
  `UnsupportedError`, `supportsTrackChanges` is still `false` and
  `QuerySnapshot.documentChanges` still throws: there is no collection
  listener here.
* The stream emits a first snapshot for the current state, including a
  non-existing one (`snapshot.exists == false`) for a missing document, then
  one snapshot per change or delete. Consecutive snapshots with the same
  `exists`/`updateTime` are skipped, so a reconnect does not duplicate.
* Resilience: the listener restarts by itself, after one second, when the
  gRPC stream errors or ends for network reasons, and it restarts whenever
  the app's http client changes (`apiClientStream`: sign-in, sign-out, token
  refresh). A `GrpcError` with `StatusCode.permissionDenied` or
  `unauthenticated` is **not** retried: it is added to the stream and the
  listener closes. Handle `onError` and re-subscribe after fixing auth.
* Always `cancel()` the subscription: it shuts the gRPC channel down.
  `firestore.dispose()` closes every listener still open on that instance.
* Auth: the bearer token is read from the app client when it is an
  `AutoRefreshingAuthClient` (service account / OAuth2). An api-key-only app
  sends no token, so the listen call is subject to the security rules for
  unauthenticated access.
* `ref.onGrpcSnapshot()` (extension `DocumentReferenceGrpcRestExt` on any
  `DocumentReference`) is the raw stream, usable on a reference from the plain
  `firestoreServiceRest` too — no automatic reconnect, no deduplication. It
  throws `UnsupportedError` for a non-REST `DocumentReference`. Prefer
  `onSnapshot()` through `firestoreServiceGrpcRest` unless you want to own the
  retry logic.
* Emulator: the channel follows `useFirestoreEmulator(host, port)` (insecure
  channel on the emulator host/port), otherwise it dials
  `firestore.googleapis.com:443` over TLS.
* Shared suites: `runFirestoreTests(firebase: firebaseRest, firestoreService:
  firestoreServiceGrpcRest, ...)` from `tekartik_firebase_firestore_test`,
  with `skipConcurrentTransactionTests = true` as for REST.

## Examples

### Listen to a document

```dart
import 'dart:async';

import 'package:tekartik_firebase_firestore_grpc_rest/firestore_grpc_rest.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<StreamSubscription<DocumentSnapshot>> watchDocument(
  FirebaseAppRest app,
  String path,
) async {
  // Same app and setup as REST, only the service changes.
  var firestore = firestoreServiceGrpcRest.firestore(app);
  var ref = firestore.doc(path);
  return ref.onSnapshot().listen(
    (snapshot) {
      if (snapshot.exists) {
        print('${snapshot.ref.path}: ${snapshot.data}');
      } else {
        print('${snapshot.ref.path}: deleted or missing');
      }
    },
    onError: (Object error) {
      // permissionDenied / unauthenticated: the listener is closed.
      print('listen failed: $error');
    },
  );
}
```

### Stop listening, and dispose every listener

```dart
import 'dart:async';

import 'package:tekartik_firebase_firestore_grpc_rest/firestore_grpc_rest.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';

/// Cancelling shuts the gRPC channel down.
Future<void> stop(StreamSubscription<DocumentSnapshot> subscription) =>
    subscription.cancel();

/// Closes all the listeners still open on this instance.
void closeAll(Firestore firestore) => firestore.dispose();
```

### Raw gRPC stream on a plain REST firestore

```dart
import 'package:tekartik_firebase_firestore_grpc_rest/firestore_grpc_rest.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

/// Works on a reference from firestoreServiceRest: no reconnect, no
/// deduplication, you own the retry.
Future<DocumentSnapshot> firstState(FirebaseAppRest app, String path) async {
  var firestore = firestoreServiceRest.firestore(app);
  return await firestore.doc(path).onGrpcSnapshot().first;
}
```

### Against the local firestore emulator

```dart
import 'package:http/http.dart';
import 'package:tekartik_firebase_firestore_grpc_rest/firestore_grpc_rest.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<FirestoreRest> emulatorGrpcFirestore(String projectId) async {
  var app =
      firebaseRest.initializeApp(
            name: 'grpc_emulator',
            options: AppOptionsRest(client: Client())..projectId = projectId,
          )
          as FirebaseAppRest;
  var firestore = firestoreServiceGrpcRest.firestore(app);
  // The gRPC channel follows this: insecure localhost:8080.
  await firestore.useFirestoreEmulator('localhost', 8080);
  return firestore;
}
```

### Running the shared firestore suite with listeners

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_firestore_grpc_rest/firestore_grpc_rest.dart';
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
  group('grpc_rest_io', () {
    if (context != null) {
      runFirestoreTests(
        firebase: firebaseRest,
        firestoreService: firestoreServiceGrpcRest,
        testContext: FirestoreTestContext()..allowedDelayInReadMs = 3000,
        options: context.options,
      );
    }
  }, skip: context == null);
}
```
