---
name: tekartik-firebase-functions-call-rest-setup
description: >-
  Use when calling a Firebase HTTPS callable Cloud Function from pure Dart
  (VM, server, CLI, web) over REST with tekartik_firebase_functions_call_rest:
  firebaseFunctionsCallServiceRest, functionsCall(app, options:
  FirebaseFunctionsCallOptions(region:)), callableFromUri(uri),
  FirebaseFunctionsCallable.call<T>(parameters),
  FirebaseFunctionsCallableResult (data, dataAsMap, dataAsMapOrNull,
  dataAsText) and the HttpsError / HttpsErrorCode failures. Read it before
  using callable(name) (unimplemented here), when the call must carry the
  signed-in user's token from tekartik_firebase_auth_rest, or when choosing
  between this and tekartik_firebase_functions_call_http.
---

# tekartik_firebase_functions_call_rest: callable functions over REST

`tekartik_firebase_functions_call_rest` implements the
`tekartik_firebase_functions_call` abstraction on top of a `FirebaseAppRest`:
it POSTs `{"data": ...}` to the function url with the app's http client and
unwraps the `{"result": ...}` / `{"error": ...}` envelope. Because it reuses
the app client, a user signed in through `tekartik_firebase_auth_rest` is
authenticated on the call for free.

## Guidelines

* Not on pub.dev. Git dependency, together with the app package (and
  `tekartik_firebase_functions` if you catch `HttpsError` by type):
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
* `package:tekartik_firebase_functions_call_rest/functions_call_rest.dart`
  exports `firebaseFunctionsCallServiceRest` and re-exports
  `package:tekartik_firebase_functions_call/functions_call.dart`
  (`FirebaseFunctionsCall`, `FirebaseFunctionsCallable`,
  `FirebaseFunctionsCallableOptions`, `FirebaseFunctionsCallableResult`,
  `FirebaseFunctionsCallOptions`, `FirebaseFunctionsCallService`, the
  `regionBelgium` / `regionUsCentral1` / `regionFrankfurt` constants and
  `package:tekartik_firebase/firebase.dart`). `HttpsError` and
  `HttpsErrorCode` are **not** re-exported: import
  `package:tekartik_firebase_functions/firebase_functions.dart` for them.
* Get the instance with `firebaseFunctionsCallServiceRest.functionsCall(app,
  options: FirebaseFunctionsCallOptions(region: regionUsCentral1))`; `app`
  must be a `FirebaseAppRest`. Instances are cached per app name + region.
* **Only `callableFromUri(uri)` is implemented.** `callable(name)` throws
  `UnimplementedError` here, so pass the full 2nd gen function url
  (`https://<function>-<hash>-<region>.a.run.app` or
  `https://<region>-<project>.cloudfunctions.net/<name>`). The `region` and
  `baseUri` of `FirebaseFunctionsCallOptions` only key the instance cache;
  they do not build the url. The optional
  `FirebaseFunctionsCallableOptions` (`timeout`,
  `limitedUseAppCheckToken`) is accepted but not applied by this
  implementation — enforce a timeout yourself with `Future.timeout` if you
  need one.
* `call<T>([parameters])` wraps `parameters` in `{'data': ...}`, as callable
  functions require, and sends `Content-Type: application/json`.
  `parameters` must be json-encodable (`String`, `num`, `bool`, `List`,
  `Map` with `String` keys, or `null`); `null` sends `{"data": null}`.
* The result's `data` is the `result` field of the response, cast to `T`. Use
  `FirebaseFunctionsCallableResultExt` for the usual shapes:
  `result.dataAsMapOrNull` (null-safe), `result.dataAsMap` (throws when not a
  map) and `result.dataAsText`. Calling `call<Map<String, Object?>>(...)`
  makes the cast explicit and fails early on an unexpected shape.
* **Every failure is an `HttpsError`**: a function throwing one, an http
  status, a network error or a bad json body (converted with
  `HttpsErrorCode.internal`). Catch `HttpsError` and branch on the `code`
  string (`HttpsErrorCode.unauthenticated`, `permissionDenied`, `notFound`,
  `invalidArgument`, `internal`...); `message` and `details` come from the
  function.
* Authentication: the callable uses `app.apiClient`, so a service-account app
  calls as the service account and an app whose client was replaced by
  `tekartik_firebase_auth_rest` calls as the signed-in user. Sign in first,
  and wait for `await auth.onCurrentUser.first`, before calling a function
  that requires auth. The client is the app's shared one: do **not** close it
  after a call, `app.delete()` owns its lifetime.
* Alternatives: `tekartik_firebase_functions_call_http`
  (`firebaseFunctionsCallServiceHttp`) when you have no `FirebaseAppRest` and
  just an http client, and `firebaseFunctionsCallServiceMemory` from its
  `functions_call_memory.dart` for in-process tests — prefer the memory
  service over mocking `FirebaseFunctionsCallable`.

## Examples

### Call a 2nd gen callable function as a service account

```dart
import 'dart:io';

import 'package:tekartik_firebase_functions_call_rest/functions_call_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

Future<Map<String, Object?>?> greet(String serviceAccountPath) async {
  var app = await firebaseRest.initializeAppWithServiceAccountString(
    File(serviceAccountPath).readAsStringSync(),
  );
  var functions = firebaseFunctionsCallServiceRest.functionsCall(
    app as FirebaseAppRest,
    options: FirebaseFunctionsCallOptions(region: regionUsCentral1),
  );
  // callable(name) is not implemented: always the full url.
  var callable = functions.callableFromUri(
    Uri.parse('https://us-central1-my-project.cloudfunctions.net/greet'),
  );
  var result = await callable.call<Map<String, Object?>>({'name': 'Alice'});
  return result.dataAsMapOrNull;
}
```

### Handle the HttpsError codes

```dart
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_call_rest/functions_call_rest.dart';

/// Every failure - thrown by the function, http, network or bad json -
/// arrives as an HttpsError.
Future<String?> callOrNull(FirebaseFunctionsCallable callable, Object? args) async {
  try {
    var result = await callable.call<Object?>(args);
    return result.dataAsText;
  } on HttpsError catch (e) {
    switch (e.code) {
      case HttpsErrorCode.unauthenticated:
      case HttpsErrorCode.permissionDenied:
        return null; // sign in again
      case HttpsErrorCode.notFound:
        throw StateError('function not deployed: ${callable.name}');
      default:
        print('${e.code}: ${e.message} ${e.details}');
        rethrow;
    }
  }
}
```

### Call as the signed-in REST user

```dart
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_functions_call_rest/functions_call_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

/// The callable reuses app.apiClient, which auth_rest replaces on sign-in.
Future<Object?> callAsUser(
  FirebaseAppRest app,
  FirebaseAuthRest auth,
  Uri uri,
) async {
  var user = await auth.onCurrentUser.first; // wait for the restore
  if (user == null) {
    throw StateError('not signed in');
  }
  var functions = firebaseFunctionsCallServiceRest.functionsCall(
    app,
    options: FirebaseFunctionsCallOptions(region: regionBelgium),
  );
  var result = await functions.callableFromUri(uri).call<Object?>({'ping': 1});
  return result.data;
}
```

### Add your own timeout

```dart
import 'package:tekartik_firebase_functions_call_rest/functions_call_rest.dart';

/// FirebaseFunctionsCallableOptions.timeout is not applied by the REST
/// implementation: wrap the call instead.
Future<T> callWithTimeout<T>(
  FirebaseFunctionsCallable callable,
  Object? parameters, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  var result = await callable.call<T>(parameters).timeout(timeout);
  return result.data;
}
```
