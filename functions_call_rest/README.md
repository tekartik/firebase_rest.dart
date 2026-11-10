# tekartik_firebase_functions_call_rest

Calls Firebase https callable functions (the `tekartik_firebase_functions_call`
API) from pure Dart with a `tekartik_firebase_rest` app: it posts
`{"data": ...}` to the function url with the app's http client and unwraps
`{"result": ...}` or `{"error": ...}`. With a user signed in through
`tekartik_firebase_auth_rest`, the call carries that user's id token. Dart VM
and web.

## Getting started

Not on pub.dev, add it as a git dependency (with the rest app, and the
functions package for `HttpsError`):

```yaml
dependencies:
  tekartik_firebase_functions_call_rest:
    git:
      url: https://github.com/tekartik/firebase_rest.dart
      path: functions_call_rest
  tekartik_firebase_rest:
    git:
      url: https://github.com/tekartik/firebase_rest.dart
      path: firebase_rest
  tekartik_firebase_functions:
    git:
      url: https://github.com/tekartik/firebase_functions.dart
      path: firebase_functions
```

```dart
import 'package:tekartik_firebase_functions/firebase_functions.dart'
    show HttpsError;
import 'package:tekartik_firebase_functions_call_rest/functions_call_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<void> main() async {
  var app = firebaseRest.initializeApp(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  var functionsCall = firebaseFunctionsCallServiceRest.functionsCall(
    app,
    options: FirebaseFunctionsCallOptions(region: regionBelgium),
  );
  // The full url of the function: callable(name) is not implemented here.
  var callable = functionsCall.callableFromUri(
    Uri.parse('https://europe-west1-my-project.cloudfunctions.net/echo'),
    options: FirebaseFunctionsCallableOptions(
      timeout: const Duration(seconds: 30),
    ),
  );
  try {
    var result = await callable.call<Map>({'value': 1});
    print(result.data);
  } on HttpsError catch (e) {
    print('${e.code}: ${e.message}');
  }
  await app.delete();
}
```

## What to know

* Only `callableFromUri(uri)` works: `callable(name)` throws
  `UnimplementedError` and `FirebaseFunctionsCallOptions.baseUri` is not
  used.
* Every failure (an error of the function, an http status, the network, a
  `timeout` of the callable options) is an `HttpsError`.
* Authentication is the app client's: a signed in `tekartik_firebase_auth_rest`
  user is seen by the function (`request.auth`). A service account app sends
  an OAuth access token, which a callable refuses (`unauthenticated`): it
  verifies Firebase id tokens.
* One `FirebaseFunctionsCall` per app object, region and base uri, released
  when the app is deleted (a new app of the same name gets its own).
* Tests: `tekartik_firebase_functions_call_http` (memory) calls a local
  function server without a real project.

The agent skill
[tekartik-firebase-functions-call-rest-setup](skills/tekartik-firebase-functions-call-rest-setup/SKILL.md)
has more examples (signed in user, error codes, timeout).
