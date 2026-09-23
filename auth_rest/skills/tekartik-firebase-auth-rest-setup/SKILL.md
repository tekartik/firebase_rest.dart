---
name: tekartik-firebase-auth-rest-setup
description: >-
  Use when signing users in from pure Dart (VM, server, CLI, web) over the
  Identity Toolkit REST API with tekartik_firebase_auth_rest: the
  firebaseAuthServiceRest singleton, FirebaseAuthServiceRest(persistence:,
  providers:), FirebaseAuthRest, useAuthEmulator, BuiltInAuthProviderRest
  (email/password + anonymous), MockBuiltInAuthProviderRest, AuthProviderRest
  and addProvider, GoogleRestAuthProvider / GoogleAuthProviderRestIo /
  GoogleAuthOptions, and the FirebaseRestAuthPersistence implementations
  (Memory, Web, File, OnPersistence over a KvStore). Also when wiring an
  auth_rest app on a FirebaseAppRest from tekartik_firebase_rest, or running
  the shared tekartik_firebase_auth_test suites against it.
---

# tekartik_firebase_auth_rest: sign in over REST

`tekartik_firebase_auth_rest` implements the `tekartik_firebase_auth`
abstraction (`FirebaseAuthService`, `FirebaseAuth`, `User`, `UserCredential`)
against Google's Identity Toolkit REST API. No native SDK: it needs a
`FirebaseAppRest` from `tekartik_firebase_rest` with an `apiKey`, and it
updates that app's http client so the other REST products (firestore, storage)
call as the signed-in user.

## Guidelines

* Not on pub.dev. Depend on it with a git dependency, plus
  `tekartik_firebase_rest` for the app:
  ```yaml
  dependencies:
    tekartik_firebase_auth_rest:
      git:
        url: https://github.com/tekartik/firebase_rest.dart
        path: auth_rest
      version: '>=0.9.2'
    tekartik_firebase_rest:
      git:
        url: https://github.com/tekartik/firebase_rest.dart
        path: firebase_rest
  ```
* Imports: `package:tekartik_firebase_auth_rest/auth_rest.dart` is the entry
  point and re-exports `package:tekartik_firebase_auth/auth.dart`, so the
  generic `FirebaseAuth`, `User`, `UserCredential`, `UserRecord` types come
  with it. `auth_rest_io.dart` adds `GoogleAuthProviderRestIo`;
  `auth_rest_web.dart` adds the web platform exports. Both re-export
  `auth_rest.dart`, import only one.
* Get the auth instance with `firebaseAuthServiceRest.auth(app)` where `app`
  is a `FirebaseAppRest` (`authServiceRest` is a compat alias of the same
  singleton). It asserts the app type, so an app from another backend fails.
  The returned object is a `FirebaseAuthRest`.
* The app options **must** carry `apiKey` for user sign-in: the built-in
  provider calls the identity toolkit with an api key client, and token
  renewal needs it too. `projectId` is required as well
  (`AppOptionsRest()..projectId = ...` then `..apiKey = ...`, or
  `FirebaseAppOptions(projectId: ..., apiKey: ...)`).
* Capabilities: `supportsCurrentUser` is `true`, `supportsListUsers` is
  `false` for the default service. `listUsers`, `getUser`, `getUsers` and
  `getUserByEmail` only work with an admin (service account) client on the
  app, failing with a permission error otherwise: for such an app use
  `firebaseAuthServiceRestAdmin` (or `FirebaseAuthServiceRest(isAdmin:
  true)`), which reports `supportsListUsers`. `listUsers` pages with the
  identity toolkit `downloadAccount` token, null on the last page.
* Providers: the default service uses a single `BuiltInAuthProviderRest`
  (email/password, provider id `password`, plus `signInAnonymously`). Build a
  service with your own list through
  `FirebaseAuthServiceRest(persistence:, providers: () => [...])`, or add one
  later with `auth.addProvider(provider)` (extension `FirebaseAuthRestExt`,
  also exposing `auth.providers`). `signIn(provider)` returns an
  `AuthSignInResult`.
* Persistence is what makes a session survive a restart. Pass one to the
  service: `FirebaseRestAuthPersistenceMemory()` (tests),
  `FirebaseRestAuthPersistenceWeb()` (browser localStorage),
  `FirebaseRestAuthPersistenceFile(fs:, directoryPath:)` (VM/Flutter, fs_shim
  `FileSystem`), or `FirebaseRestAuthPersistenceOnPersistence(kvStore)` over
  any `KvStore` (`TekartikFirebasePersistenceSdb`, ...). Without persistence
  the user is signed out at every start. Credentials are stored per
  `projectId`.
* A restore is asynchronous: `auth.currentUser` is `null` until it completed.
  Always start from `await auth.onCurrentUser.first` (it replays the current
  value), then keep listening for sign-in/sign-out.
* Emulator: `await auth.useAuthEmulator('localhost', 9099)` immediately after
  `authService.auth(app)` and before any auth call. Use a dummy `apiKey`
  (`'dummy'`) with it and never point it at production credentials.
* `MockBuiltInAuthProviderRest` extends the built-in provider and fakes
  `signInWithEmailAndPassword` / `signInAnonymously` with a
  `mock_id_token`: pass it as the `providers:` of a service in unit tests so
  nothing hits the network.
* Shared suites: `runAuthTests(firebase: firebaseRest, authService:
  firebaseAuthServiceRest, options:, name:)` from
  `package:tekartik_firebase_auth_test/auth_test.dart`, and
  `firebaseAuthSignInDeleteTests(getAuth:, email:, password:)` from
  `auth_sign_in_delete_test_runner.dart` (both dev dependencies of this
  package).
* `GoogleRestAuthProvider` signs in with a Google OAuth2 client
  (`googleapis_auth`). On the VM use `GoogleAuthProviderRestIo(options:
  GoogleAuthOptions(...), credentialPath:, userPrompt:,
  credentialsPersistence:, credentialsKey:)` from `auth_rest_io.dart`; it
  throws `UnsupportedError` off the VM. `GoogleAuthOptions.fromMap(map)`
  reads a yaml/json config with `clientId`/`client_id`,
  `clientSecret`/`client_secret`, `apiKey`/`api_key`, `projectId` and
  `developerKey`. `PromptUserForConsentRest` is the `void Function(String uri)`
  that shows the consent url.
* Set `debugFirebaseAuthRest = true` to trace the REST calls while debugging.
  Never log id tokens, refresh tokens or the client secret.
* Do not build sign-in UI directly on this: the generic
  `tekartik_firebase_ui_auth` works with any backend, this one included.

## Examples

### Service with file persistence, signed-in user at startup

```dart
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<FirebaseAuthRest> initAuth({
  required String projectId,
  required String apiKey,
}) async {
  var app =
      firebaseRest.initializeApp(
            options: AppOptionsRest()
              ..projectId = projectId
              ..apiKey = apiKey,
          )
          as FirebaseAppRest;
  var authService = FirebaseAuthServiceRest(
    persistence: FirebaseRestAuthPersistenceFile(directoryPath: '.local/auth'),
  );
  var auth = authService.auth(app);
  // Wait for the persisted session to be restored.
  var user = await auth.onCurrentUser.first;
  print('restored: ${user?.uid}');
  return auth;
}
```

### Sign in, observe, sign out

```dart
import 'dart:async';

import 'package:tekartik_firebase_auth_rest/auth_rest.dart';

Future<User> signIn(
  FirebaseAuthRest auth, {
  required String email,
  required String password,
}) async {
  var credential = await auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  return credential.user;
}

StreamSubscription<User?> watch(FirebaseAuthRest auth) =>
    auth.onCurrentUser.listen((user) {
      print(user == null ? 'signed out' : 'signed in ${user.uid}');
    });

Future<void> guest(FirebaseAuthRest auth) async {
  await auth.signInAnonymously();
  await auth.signOut();
}
```

### Against the local auth emulator

```dart
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<FirebaseAuthRest> emulatorAuth(String projectId) async {
  var app = await firebaseRest.initializeAppAsync(
    name: 'emulator',
    options: FirebaseAppOptions(projectId: projectId, apiKey: 'dummy'),
  );
  var auth = firebaseAuthServiceRest.auth(app as FirebaseAppRest);
  // Immediately, before any other auth call.
  await auth.useAuthEmulator('localhost', 9099);
  return auth;
}
```

### Offline unit test with the mock provider

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

void main() {
  var authService = FirebaseAuthServiceRest(
    persistence: FirebaseRestAuthPersistenceMemory(),
    providers: () => [MockBuiltInAuthProviderRest()],
  );
  group('auth_rest_mock', () {
    test('capabilities', () {
      expect(authService.supportsCurrentUser, isTrue);
      expect(authService.supportsListUsers, isFalse);
    });
    runAuthTests(
      firebase: firebaseRest,
      authService: authService,
      options: FirebaseAppOptions(projectId: 'test'),
    );
  });
}
```

### Google sign-in on the Dart VM

```dart
import 'package:tekartik_firebase_auth_rest/auth_rest_io.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<User?> googleSignInIo(Map configMap) async {
  var options = GoogleAuthOptions.fromMap(configMap);
  var app =
      firebaseRest.initializeApp(
            options: AppOptionsRest()
              ..projectId = options.projectId
              ..apiKey = options.apiKey,
          )
          as FirebaseAppRest;
  var auth = firebaseAuthServiceRest.auth(app);
  var provider = GoogleAuthProviderRestIo(
    options: options,
    credentialPath: '.local/google.credentials.yaml',
    userPrompt: (uri) => print('open $uri to authorize'),
  );
  auth.addProvider(provider);
  var user = await auth.onCurrentUser.first;
  if (user == null) {
    var result = await auth.signIn(provider);
    user = result.credential?.user;
  }
  return user;
}
```
