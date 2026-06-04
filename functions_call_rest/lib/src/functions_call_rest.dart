// ignore: depend_on_referenced_packages
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_functions_call/functions_call_mixin.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_http_mixin.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_http/http.dart' as http;

/// Rest call service
final firebaseFunctionsCallServiceRest = _FirebaseFunctionsCallServiceRest();

/// Rest implementation
abstract class FirebaseFunctionsCallServiceRest
    implements FirebaseFunctionsCallService {}

/// Firebase functions call service Http
class _FirebaseFunctionsCallServiceRest
    with
        FirebaseProductServiceMixin<FirebaseFunctionsCall>,
        FirebaseFunctionsCallServiceDefaultMixin
    implements FirebaseFunctionsCallServiceRest {
  /// Constructor
  _FirebaseFunctionsCallServiceRest();

  /// Most implementation need a single instance, keep it in memory!
  final _instances = <String, FirebaseFunctionsCallRest>{};

  FirebaseFunctionsCallRest _getInstance(
    App app,
    String region,
    FirebaseFunctionsCallRest Function() createIfNotFound,
  ) {
    var key = '${app.name}_$region';
    var instance = _instances[key];
    if (instance == null) {
      var newInstance = instance = createIfNotFound();
      _instances[key] = newInstance;
    }
    return instance;
  }

  @override
  FirebaseFunctionsCall functionsCall(
    App app, {
    required FirebaseFunctionsCallOptions options,
  }) {
    return _getInstance(app, options.region, () {
      return _FirebaseFunctionsCallRest(this, app as FirebaseAppRest, options);
    });
  }
}

/// Firebase functions call rest
abstract class FirebaseFunctionsCallRest implements FirebaseFunctionsCall {}

/// Firebase functions call Http
class _FirebaseFunctionsCallRest
    with
        FirebaseAppProductMixin<FirebaseFunctionsCall>,
        FirebaseFunctionsCallDefaultMixin
    implements FirebaseFunctionsCallRest {
  /// Service
  @override
  final FirebaseFunctionsCallServiceRest service;

  /// App
  @override
  final FirebaseAppRest app;

  /// Options
  final FirebaseFunctionsCallOptions options;

  /// Firestore api.
  http.Client get client => app.apiClient;

  /// Constructor
  _FirebaseFunctionsCallRest(this.service, this.app, this.options);

  @override
  FirebaseFunctionsCallableRest callableFromUri(
    Uri uri, {
    FirebaseFunctionsCallableOptions? options,
  }) {
    return _FirebaseFunctionsCallableRest(this, uri: uri);
  }
}

/// Firebase functions callable Http.
abstract class FirebaseFunctionsCallableRest
    implements FirebaseFunctionsCallable {}

// # The Required Headers
// Your REST request must include the following headers, or Firebase will reject it:
//
// Content-Type: application/json
//
// Authorization: Bearer <FIREBASE_ID_TOKEN> (Optional: Only required if your function expects an authenticated user)
//
// # The Request Body (The Critical Part)
// Unlike a standard HTTP function where you can pass any JSON object, a Callable function strictly requires your data to be wrapped inside a top-level data key.
//
// Incorrect (Standard REST):
// JSON
// {
//   "username": "johndoe",
//   "email": "john@example.com"
// }
// Correct (Firebase Callable REST):
// JSON
// {
//   "data": {
//     "username": "johndoe",
//     "email": "john@example.com"
//   }
// }
// ⚠️ Note: If your function doesn't require any inputs, you must still pass an empty data object: {"data": {}}. If you omit the data key entirely, the request will fail.
//
// # Example: Making the Request via curl
// Here is a complete example of how to call your function from the command line:
//
// Bash
// curl -X POST https://us-central1-my-awesome-project.cloudfunctions.net/myCallableFunction \
//   -H "Content-Type: application/json" \
//   -H "Authorization: Bearer YOUR_AUTH_TOKEN_HERE" \
//   -d '{
//     "data": {
//       "text": "Hello from REST!"
//     }
//   }'
// # Understanding the Response
// Just like the request, Firebase will automatically wrap the successful response from your function inside a top-level result key.
//
// If your function returns return { status: "success", message: "User created" };, the REST response you receive will look like this:
//
// JSON
// {
//   "result": {
//     "status": "success",
//     "message": "User created"
//   }
// }
// Handling Errors
// If the function throws a HttpsError, Firebase will return a 4xx or 5xx HTTP status code, and the body will look like this:
//
// JSON
// {
//   "error": {
//     "status": "INVALID_ARGUMENT",
//     "message": "The password is too short.",
//     "details": { "minCharacters": 8 }
//   }
// }
class _FirebaseFunctionsCallableRest
    with FirebaseFunctionsCallableDefaultMixin
    implements FirebaseFunctionsCallableRest {
  late final Uri? uri;

  /// The function name
  @override
  late final String name;

  /// Functions call Http
  final _FirebaseFunctionsCallRest functionsCallRest;

  /// Constructor
  _FirebaseFunctionsCallableRest(
    this.functionsCallRest, {
    Uri? uri,
    String? name,
  }) {
    this.uri = uri;
    if (uri != null) {
      this.name = name ?? uri.toString();
    } else {
      throw UnsupportedError('Uri is required for Http callable for REST');
      // this.name = name!;
    }
  }

  @override
  Future<FirebaseFunctionsCallableResult<T>> call<T>([
    Object? parameters,
  ]) async {
    var httpClient = functionsCallRest.client;
    var uri = this.uri!;
    return await firebaseFunctionsHttpCallUri(
      httpClient,
      uri,
      parameters: parameters,
    );
  }

  @override
  String toString() => 'CallableHttp($name)';
}
