# tekartik_firebase_auth_rest

Firebase Auth over the Identity Toolkit REST API, in pure Dart: an
implementation of [tekartik_firebase_auth](https://github.com/tekartik/firebase_auth.dart/tree/main/auth)
on an app of [tekartik_firebase_rest](../firebase_rest/README.md). Email and
password, anonymous and Google sign in, id token renewal, sessions persisted
where you choose, and the admin lookups (`getUser`, `listUsers`) with a
service account.

Runs on the Dart VM (servers, CLI, desktop) and on the web; the Google
consent providers (`auth_rest_io.dart`) are VM only. In a Flutter app prefer
the native `tekartik_firebase_auth_flutter`.

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_auth_rest:
    git:
      url: https://github.com/tekartik/firebase_rest.dart
      path: auth_rest
  tekartik_firebase_rest:
    git:
      url: https://github.com/tekartik/firebase_rest.dart
      path: firebase_rest
```

```dart
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<void> main() async {
  // The web api key of the project (Firebase console, project settings).
  var app = firebaseRest.initializeApp(
    options: FirebaseAppOptions(projectId: 'my-project', apiKey: 'my-api-key'),
  );
  var authService = FirebaseAuthServiceRest(
    // Where the session is kept (memory, file, web local storage, any KvStore).
    persistence: FirebaseRestAuthPersistenceMemory(),
  );
  var auth = authService.auth(app);

  // A persisted session is restored first.
  var user = await auth.onCurrentUser.first;
  if (user == null) {
    var credential = await auth.signInWithEmailAndPassword(
      email: 'bob@example.com',
      password: 'password1',
    );
    user = credential.user;
  }
  print('signed in as ${user.uid}');

  await auth.signOut();
  await app.delete();
}
```

Once signed in, the products of the same app (`tekartik_firebase_firestore_rest`,
`tekartik_firebase_storage_rest`...) call as the user; signed out, they call
as the app did before (api key, or its service account client).

## When to use what

| Need | Use |
|---|---|
| sign users in from Dart | `firebaseAuthServiceRest` or `FirebaseAuthServiceRest(persistence:)` |
| admin lookups (`getUser`, `getUserByEmail`, `listUsers`) | an app initialized with a service account and `firebaseAuthServiceRestAdmin` |
| the local auth emulator | `await auth.useAuthEmulator('localhost', 9099)` right after `auth(app)` |
| offline unit tests | `FirebaseAuthServiceRest(providers: () => [MockBuiltInAuthProviderRest()])` |
| a Google user of the app from a desktop tool | `GoogleIdpAuthProviderRestIo` (`auth_rest_io.dart`) |
| id tokens of the signed in user | `(user as UserInfoWithIdToken).getIdToken()` (renewed when expiring) |

## Pitfalls

* The app options need the `apiKey` (sign in and token renewal) and the
  `projectId`.
* `auth.currentUser` is null until the persisted session is restored: start
  from `await auth.onCurrentUser.first`.
* Without persistence the user is signed out at every start.
* `verifyIdToken` is not implemented (no server side check here).
* `debugFirebaseAuthRest = true` prints the raw responses, the password
  hashes of `listUsers` included: local debugging only. The `toString` of the
  persisted credentials and of `GoogleAuthOptions` hold tokens and the client
  secret: never print them.
* Anonymous and email sign up on a real project: check that the session
  survives the first hour (token renewal) in your setup.

The skills have more examples:
[setup](skills/tekartik-firebase-auth-rest-setup/SKILL.md) (providers,
persistence, emulator, Google sign in) and
[tokens](skills/tekartik-firebase-auth-rest-tokens/SKILL.md) (renewal, bearer
headers).
