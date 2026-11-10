# tekartik_firebase_firestore_grpc_rest

Document listeners (`onSnapshot`) for the pure Dart Firestore REST client
`tekartik_firebase_firestore_rest`, through the Firestore v1 gRPC `Listen`
call. Everything else (reads, writes, queries, transactions) stays on REST.
Dart VM only (gRPC needs `dart:io` sockets): servers, scripts, desktop.

## Getting started

Not on pub.dev, add it as a git dependency (with the REST packages it builds
on):

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
  tekartik_firebase_rest:
    git:
      url: https://github.com/tekartik/firebase_rest.dart
      path: firebase_rest
```

Use `firestoreServiceGrpcRest` where you used `firestoreServiceRest`, the app
setup is the REST one (see `tekartik_firebase_firestore_rest`):

```dart
import 'dart:async';

import 'package:tekartik_firebase_firestore_grpc_rest/firestore_grpc_rest.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

StreamSubscription<DocumentSnapshot> watch(FirebaseAppRest app, String path) {
  var firestore = firestoreServiceGrpcRest.firestore(app);
  return firestore
      .doc(path)
      .onSnapshot()
      .listen(
        (snapshot) => print('${snapshot.ref.path}: ${snapshot.dataOrNull}'),
        // A GrpcError: permissionDenied (the rules), unauthenticated.
        onError: (Object error) => print('listen failed: $error'),
      );
}
```

Cancel the subscription to close the connection.

## What to know

* Documents only: `Query.onSnapshot()` is still unsupported.
* The first snapshot is the current state (`exists` false for a missing
  document), then one per change; a reconnection does not repeat a state.
* The listener reconnects by itself (network errors, the server closing the
  connection: from 1 s up to 60 s) and on each auth change of the app (sign
  in, sign out). A refusal of the security rules ends the stream with a
  `GrpcError` (`StatusCode.permissionDenied`).
* `ref.onGrpcSnapshot()` is the raw stream of one connection (no reconnect),
  usable on a plain `firestoreServiceRest` reference.

## Testing

`dart test` (VM): the listener and gRPC tests use a local mock server; the
`*_io_test.dart` files run against a real project when a git-ignored
`test/local.service_account.json` is present. The agent skill
[tekartik-firebase-firestore-grpc-rest-listen](skills/tekartik-firebase-firestore-grpc-rest-listen/SKILL.md)
has more examples (emulator, shared test suite).
