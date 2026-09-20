---
name: tekartik-firebase-rest-setup
description: >-
  Use when initializing Firebase from pure Dart (VM, server, web) over REST
  instead of the native/Flutter SDK with tekartik_firebase_rest: the
  firebaseRest singleton, initializeAppWithServiceAccountMap /
  initializeAppWithServiceAccountString, FirebaseAdminCredentialRest
  (fromServiceAccountJson/fromServiceAccountMap, initAuthClient),
  AppOptionsRest / FirebaseAppOptionsRest, FirebaseAppRest (client, apiClient,
  apiClientStream, hasAdminCredentials), getAppOptionsFromAccessToken,
  firebaseBaseScopes / firebaseGoogleApisCloudPlatformScope /
  firebaseGoogleApisFirebaseRulesApiScope, getFirestoreRules, and the
  firebaseRestSetupContext / FirebaseRestSetupContext test helpers. This is the
  app that auth_rest, firestore_rest, storage_rest and functions_call_rest
  plug into.
---

# tekartik_firebase_rest: REST FirebaseApp and credentials

`tekartik_firebase_rest` implements the `tekartik_firebase` `Firebase` /
`FirebaseApp` abstractions on top of `googleapis_auth` and `package:http`: no
native SDK, no Flutter plugin, just an authenticated `Client` carried by the
app. Every other `*_rest` package of this repo (auth, firestore, storage,
functions call) takes that app and reuses its client.

## Guidelines

* Not on pub.dev (`publish_to: none`). Depend on it with a git dependency:
  ```yaml
  dependencies:
    tekartik_firebase_rest:
      git:
        url: https://github.com/tekartik/firebase_rest.dart
        path: firebase_rest
      version: '>=0.8.4'
  ```
  It brings `tekartik_firebase` (`https://github.com/tekartik/firebase.dart`,
  `path: firebase`); declare that one explicitly too if you import it directly.
* `package:tekartik_firebase_rest/firebase_rest.dart` re-exports
  `package:tekartik_firebase/firebase.dart` (`Firebase`, `FirebaseApp`, `App`,
  `AppOptions`, `FirebaseAppOptions`), so one import is usually enough.
  `package:tekartik_firebase_rest/firebase_rest_setup.dart` adds
  `firebaseGoogleApisFirebaseRulesApiScope` and the
  `firebaseRestSetupContext` / `FirebaseRestSetupContext` test helpers (it
  re-exports `firebase_rest.dart`, import only one of the two).
* `firebaseRest` is the singleton `FirebaseAdminRest` (a `Firebase` plus the
  admin `credential` service). Every app it creates is a `FirebaseAppRest`:
  cast the result of `initializeApp` when you need `client` / `apiClient`.
* Two ways to initialize, both on `firebaseRest`
  (extension `FirebaseAdminRestExtension`):
  `initializeAppWithServiceAccountMap(map, options:, scopes:)` and
  `initializeAppWithServiceAccountString(json, options:, scopes:)`. Both set
  the application-default credential, obtain an auto-refreshing auth client
  and return the app; `projectId` comes from the service account.
* Lower level: build a `FirebaseAdminCredentialRest` (alias of
  `FirebaseAdminCredentialsRest`) with `.fromServiceAccountJson(json,
  scopes:)` or `.fromServiceAccountMap(map, scopes:)`, `await
  credential.initAuthClient()`, then
  `firebaseRest.credential.setApplicationDefault(credential)` and
  `await firebaseRest.initializeAppAsync()`. The credential exposes
  `projectId`, `authClient` and `appOptions`.
* `initializeApp({options, name})` is synchronous and does **not** refresh the
  auth client: use it only with options that already carry a client, or after
  `setApplicationDefault`. With neither options nor an application default
  credential it throws a `StateError`. `initializeAppAsync` is the safe
  default. Names must be unique per process: re-initializing an existing name
  throws a `StateError` until `await app.delete()`.
* `scopes:` defaults to `firebaseBaseScopes`
  (`firebaseGoogleApisCloudPlatformScope` +
  `firebaseGoogleApisUserEmailScope`). Add
  `firebaseGoogleApisFirebaseRulesApiScope` (from `firebase_rest_setup.dart`)
  when reading firestore rules, and the auth/firestore/storage packages'
  own scopes when they ask for them.
* `AppOptionsRest` is a typedef of `FirebaseAppOptionsRest`. Its factory takes
  `client:` (an authenticated `package:http` `Client`), `apiKey:`,
  `storageBucket:` and `identifyServiceAccount:`; `projectId` is set after
  construction (`AppOptionsRest(...)..projectId = 'my-project'`).
  `copyWith({apiKey, storageBucket})` keeps client, projectId and identity.
* For a token obtained elsewhere (browser sign-in, `gcloud`, a delegated
  flow), use `getAppOptionsFromAccessToken(client, token, projectId:,
  scopes:, originalOptions:)`: it wraps the raw `Client` in an authenticated
  one and returns ready-to-use options. Expiry is ignored, so refresh the app
  options yourself when the token expires.
* On a `FirebaseAppRest`: `client` is the current (possibly null) http client,
  `apiClient` is never null (it lazily creates a plain unauthenticated
  `Client`), and `apiClientStream` broadcasts each new client so services
  built on the app can follow a re-authentication. The `client` setter is
  `@protected` — it is meant for the auth package updating the app after a
  sign-in, not for application code. `hasAdminCredentials` is `true` only when
  the app was initialized from a service account.
* `app.getFirestoreRules()` (extension `FirebaseAppRestExt`) returns the
  source of the current `cloud.firestore` ruleset through the
  `googleapis` FirebaseRules API; it needs
  `firebaseGoogleApisFirebaseRulesApiScope` and an authenticated client.
* An app with no credentials is legitimate when talking to an emulator or to
  public rules: pass `AppOptionsRest(client: Client())..projectId = ...`.
* Tests: `firebaseRestSetupContext({scopes, useEnv, serviceAccountJsonPath,
  serviceAccountMap})` returns `null` (after printing the error) instead of
  throwing when no credentials are available — always null-check it and
  declare a dummy `test(...)` so the file is not empty. It reads
  `test/local.service_account.json` by default, or the
  `TEKARTIK_FIREBASE_REST_TEST_SERVICE_ACCOUNT` environment variable (raw json
  or a path) with `useEnv: true`. The context gives `client`, `authClient`,
  `options`, `valid`, `projectId` and `app` (a fresh `FirebaseAppRest`).
  `package:tekartik_firebase_rest/test/setup.dart` is the `dart:io` variant
  (`setup`, plus `runningOnGithub`, `isGithubActionsEnvTest()`,
  `shouldSkipEnvTestOnGithub()`, `githubActionsPrefix`) used to skip
  credential-dependent tests on CI.
* The shared `tekartik_firebase_test` suite runs against this implementation:
  `runFirebaseTests(firebaseRest, options: context.options)` from
  `package:tekartik_firebase_test/firebase_test.dart` (a dev dependency).
* Never commit `test/local.service_account.json`; never log the service
  account json or the access token.

## Examples

### Initialize from a service account json file (VM / server)

```dart
import 'dart:io';

import 'package:tekartik_firebase_rest/firebase_rest.dart';

/// Initializes the default REST app with admin credentials.
Future<FirebaseAppRest> initRestApp(String serviceAccountPath) async {
  var app = await firebaseRest.initializeAppWithServiceAccountString(
    File(serviceAccountPath).readAsStringSync(),
    scopes: firebaseBaseScopes,
  );
  print('project: ${app.options.projectId}');
  return app as FirebaseAppRest;
}
```

### Explicit credential, named app, clean shutdown

```dart
import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<void> useNamedApp(Map serviceAccountMap) async {
  var credential = FirebaseAdminCredentialRest.fromServiceAccountMap(
    serviceAccountMap,
    scopes: firebaseBaseScopes,
  );
  await credential.initAuthClient();
  firebaseRest.credential.setApplicationDefault(credential);

  var app =
      await firebaseRest.initializeAppAsync(name: 'admin') as FirebaseAppRest;
  try {
    print('${app.name} ${app.options.projectId} ${app.hasAdminCredentials}');
  } finally {
    await app.delete(); // the name can be reused after this
  }
}
```

### App from an OAuth2 access token, and an anonymous app

```dart
import 'package:http/http.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

/// App built from a token obtained elsewhere (browser sign-in, gcloud...).
FirebaseAppRest appFromAccessToken(String accessToken, String projectId) {
  var options = getAppOptionsFromAccessToken(
    Client(),
    accessToken,
    projectId: projectId,
    scopes: firebaseBaseScopes,
    originalOptions: null,
  );
  return firebaseRest.initializeApp(options: options, name: 'token_app')
      as FirebaseAppRest;
}

/// No credentials: emulator or fully public rules.
FirebaseAppRest anonymousApp({required String projectId}) {
  return firebaseRest.initializeApp(
        options: AppOptionsRest(client: Client())..projectId = projectId,
        name: 'no_auth',
      )
      as FirebaseAppRest;
}
```

### Follow client changes and read the firestore rules

```dart
import 'dart:async';

import 'package:http/http.dart';
import 'package:tekartik_firebase_rest/firebase_rest_setup.dart';

/// Re-create anything holding the client when the app re-authenticates.
StreamSubscription<Client> watchApiClient(FirebaseAppRest app) {
  return app.apiClientStream.listen((client) {
    print('new api client $client');
  });
}

/// Needs [firebaseGoogleApisFirebaseRulesApiScope] in the app scopes.
Future<String> dumpRules(FirebaseAppRest app) async {
  print('scope: $firebaseGoogleApisFirebaseRulesApiScope');
  return await app.getFirestoreRules();
}
```

### Credential-aware test file

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_rest/firebase_rest_setup.dart';
import 'package:test/test.dart';

Future<void> main() async {
  // Reads test/local.service_account.json, or
  // TEKARTIK_FIREBASE_REST_TEST_SERVICE_ACCOUNT with useEnv: true.
  var context = await firebaseRestSetupContext(scopes: firebaseBaseScopes);
  if (context == null) {
    test('no rest credentials available', () {});
    return;
  }
  group('rest', () {
    test('context', () {
      expect(context.valid, isTrue);
      expect(context.projectId, isNotEmpty);
    });
    test('app', () async {
      var app = context.app;
      expect(app.hasAdminCredentials, isTrue);
      await app.delete();
    });
  });
}
```
