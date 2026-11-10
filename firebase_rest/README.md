# tekartik_firebase_rest

Firebase app over REST, in pure Dart (Dart VM, servers, CLI tools): the
[tekartik_firebase](https://github.com/tekartik/firebase.dart/tree/master/firebase)
`Firebase` / `FirebaseApp` API on `googleapis_auth` and `package:http`, no
native SDK. The other packages of this repo plug their product into its app:
`auth_rest`, `firestore_rest`, `storage_rest`, `functions_call_rest`.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_rest:
    git:
      url: https://github.com/tekartik/firebase_rest.dart
      path: firebase_rest
```

With a service account (admin access, Dart VM):

```dart
import 'dart:io';

import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<void> main() async {
  // Never commit nor print the service account json.
  var app = await firebaseRest.initializeAppWithServiceAccountString(
    File('local.service_account.json').readAsStringSync(),
  );
  print(app.options.projectId);
  // Then: firestoreServiceRest.firestore(app), storageServiceRest...
  await app.delete();
}
```

Without credentials (emulator, public rules):

```dart
import 'package:http/http.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

FirebaseApp anonymousApp() => firebaseRest.initializeApp(
  options: AppOptionsRest(client: Client())..projectId = 'my-project',
  name: 'anonymous',
);
```

## When to use what

* `initializeAppWithServiceAccountString` / `...Map`: admin app, an auto
  refreshing client, the project id of the service account.
* `initializeApp(options: AppOptionsRest(client: ...))`: a client you built
  (an emulator, a signed in user through `auth_rest`).
* `getAppOptionsFromAccessToken(...)`: an OAuth access token obtained
  elsewhere (its expiry is not handled).
* `app.getFirestoreRules()` (scope `firebaseGoogleApisFirebaseRulesApiScope`
  of `firebase_rest_setup.dart`): the source of the latest firestore ruleset.

## Pitfalls

* Once a credential is set, `initializeApp(options: ...)` only keeps the
  `apiKey` and `storageBucket` of the given options: the project and the
  client come from the credential.
* `credential.getAccessToken()` caches its token for the whole process (no
  refresh after its expiry, about an hour) and replaces the auto refreshing
  client of the next apps: in a long running process, initialize the apps with
  `initializeAppWithServiceAccount...` / `initializeAppAsync` and do not call
  it.
* App names are unique per process: `await app.delete()` before initializing
  the same name again.

## Agent skills

`skills/tekartik-firebase-rest-setup` (credentials, options, test setup).
