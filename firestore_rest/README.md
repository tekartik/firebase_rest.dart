# tekartik_firebase_firestore_rest

Cloud Firestore from pure Dart over the Firestore v1 REST API: the
`tekartik_firebase_firestore` API (documents, queries, batches,
transactions, aggregate queries) on a `FirebaseAppRest` of
`tekartik_firebase_rest`, with a service account, a signed in user or no
credentials at all (public rules, emulator). No realtime listener.

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_firestore_rest:
    git:
      url: https://github.com/tekartik/firebase_rest.dart
      path: firestore_rest
  tekartik_firebase_rest:
    git:
      url: https://github.com/tekartik/firebase_rest.dart
      path: firebase_rest
  # The http client of the emulator example below.
  http: ">=1.2.0"
```

With a service account (server, CLI):

```dart
import 'dart:io';

import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<void> main() async {
  var app = await firebaseRest.initializeAppWithServiceAccountString(
    File('service_account.json').readAsStringSync(),
    scopes: [firestoreGoogleApisAuthDatastoreScope],
  );
  var firestore = firestoreServiceRest.firestore(app as FirebaseAppRest);

  var ref = firestore.collection('users').doc('alice');
  await ref.set({'name': 'Alice', 'updated': FieldValue.serverTimestamp});
  print((await ref.get()).data);
  var adults = await firestore
      .collection('users')
      .where('age', isGreaterThanOrEqualTo: 18)
      .get();
  print(adults.docs.map((doc) => doc.ref.id).toList());
  await app.delete();
}
```

Against the emulator, without credentials:

```dart
import 'package:http/http.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<FirestoreRest> emulatorFirestore() async {
  var app =
      firebaseRest.initializeApp(
            options: AppOptionsRest(client: Client())..projectId = 'demo',
          )
          as FirebaseAppRest;
  var firestore = firestoreServiceRest.firestore(app);
  // owner: true bypasses the security rules (emulator only).
  await firestore.useFirestoreEmulator('localhost', 8080, owner: true);
  return firestore;
}
```

## Platforms

Dart VM, web and Flutter (plain http). Reading a service account file needs
`dart:io`; in a browser use a signed in user (`tekartik_firebase_auth_rest`)
or public rules.

## What to know

* `firestore_rest.dart` re-exports the firestore API (`Firestore`,
  `FieldValue`, `Timestamp`...). One `FirestoreRest` per app.
* No realtime: `onSnapshot()` and `documentChanges` throw
  `UnsupportedError` (`supportsTrackChanges` false). Poll with `get()`, or use
  `tekartik_firebase_firestore_grpc_rest` for listeners.
* Transactions need an authenticated app (`supportsTransaction`, known once
  the auth is ready): a service account or an OAuth2 user. A commit aborted
  by contention fails instead of being retried. `batch()` always works.
* `FieldValue.serverTimestamp` and `FieldValue.increment` are supported (not
  inside an array), array `FieldValue`s and snapshot cursors are not.
* Listing missing documents needs admin access (service account, or the
  emulator owner).
* Errors are `FirestoreException`s (`notFound`, `unauthenticated`,
  `permissionDenied`, `internal`, else `unknown` with the http status).
* `debugFirestoreRest = true` prints every request and response.
* `package:tekartik_firebase_firestore_rest/snapshot.dart` converts a
  snapshot to the REST JSON (`snapshotToJson`).

The skills [tekartik-firebase-firestore-rest-setup](skills/tekartik-firebase-firestore-rest-setup/SKILL.md)
and [tekartik-firebase-firestore-rest-json](skills/tekartik-firebase-firestore-rest-json/SKILL.md)
have more examples (queries, batches, transaction guard, polling, shared
test suite, json helpers).
