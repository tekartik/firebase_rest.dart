/// Https callable functions called over REST with a `tekartik_firebase_rest`
/// app ([firebaseFunctionsCallServiceRest]): the app's http client (a signed
/// in user's id token) posts `{"data": ...}` to the function url given to
/// `callableFromUri`. Re-exports `tekartik_firebase_functions_call`.
library;

export 'package:tekartik_firebase_functions_call/functions_call.dart';

export 'src/functions_call_rest.dart' show firebaseFunctionsCallServiceRest;
