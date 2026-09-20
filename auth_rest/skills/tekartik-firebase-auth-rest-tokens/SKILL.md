---
name: tekartik-firebase-auth-rest-tokens
description: >-
  Use when handling Firebase id tokens with tekartik_firebase_auth_rest:
  RestAuthTokens (idToken, refreshToken, expiresAt, fromSignIn, canRefresh,
  isExpiring, isExpired, update), RestAuthTokenRefresher (securetoken
  googleapis refresh with an apiKey, rootUrl for the emulator),
  RestAuthTokenRefreshException and isSessionExpired, idTokenExpiration
  (reading the jwt `exp` claim), getIdToken(forceRefresh:) on a
  UserInfoWithIdToken, and the getAuthorizationHeader /
  parseAuthorizationHeaderToken bearer-header helpers. Also when a REST
  session expires, when a call returns 401, or when verifyIdToken throws
  UnsupportedError.
---

# tekartik_firebase_auth_rest: id tokens and refresh

A REST sign-in hands back a short-lived id token (a jwt, about an hour) and a
refresh token. `tekartik_firebase_auth_rest` keeps them in a `RestAuthTokens`
and renews them through the secure token API. These types are exported by
`package:tekartik_firebase_auth_rest/auth_rest.dart` and are usable on their
own, without a `FirebaseAuth` instance.

## Guidelines

* Import `package:tekartik_firebase_auth_rest/auth_rest.dart`: it exports
  `RestAuthTokens`, `RestAuthTokenRefresher`,
  `RestAuthTokenRefreshException`, `idTokenExpiration`,
  `getAuthorizationHeader`, `parseAuthorizationHeaderToken`, plus the generic
  auth types (`UserInfoWithIdToken`, `DecodedIdToken`).
* `RestAuthTokens` is **mutable on purpose**: `update(other)` replaces the id
  token in place so a client holding the instance sends the new one from then
  on. Do not copy it around; share the instance.
* Build it from a sign-in response with
  `RestAuthTokens.fromSignIn(idToken:, refreshToken:, expiresIn:, now:)`
  (`expiresIn` is the identity toolkit's seconds-as-string), or directly with
  `RestAuthTokens(idToken:, refreshToken:, expiresAt:)`. When `expiresIn` is
  missing it falls back to the jwt `exp` claim.
* Expiry: `expiration` is `expiresAt` or the `exp` claim;
  `isExpiring({margin = Duration(minutes: 5), now})` is `false` when the
  expiration is unknown; `isExpired({now})` is `isExpiring` with a zero
  margin. `canRefresh` is `refreshToken != null` — a session persisted
  without a refresh token can only be used until its id token expires, then
  the user must sign in again.
* `idTokenExpiration(idToken)` decodes the `exp` claim of a jwt and returns
  `null` for anything that is not one (it never throws): good for a quick
  check on a token received from elsewhere. It does **not** verify the
  signature.
* `RestAuthTokenRefresher({required apiKey, rootUrl, clientFactory})` posts
  to `securetoken.googleapis.com/v1/token`. `apiKey` is the app's api key;
  `rootUrl` is the auth emulator root (`http://localhost:9099/`) and is left
  `null` for production; `clientFactory` lets you inject a `MockClient` in
  tests (a fresh default `Client` per call otherwise, closed afterwards).
  `refresh(refreshToken)` returns fresh `RestAuthTokens`.
* A failed refresh throws `RestAuthTokenRefreshException` with `statusCode`,
  the api `code` (`TOKEN_EXPIRED`, `INVALID_REFRESH_TOKEN`, `USER_DISABLED`,
  `USER_NOT_FOUND`...) and `message`. Branch on `isSessionExpired` (400, 401,
  403): sign the user out and ask for credentials again. Anything else is
  transient (network, server) — retry, keep the session.
* With a `FirebaseAuth` from this package you normally do not refresh by
  hand: the provider renews the token on its own when it is expiring, before
  every request and when restoring a persisted session. Get the current token
  with `(user as UserInfoWithIdToken).getIdToken(forceRefresh: true)`; it
  throws a `StateError` when nobody is signed in, and `UnsupportedError` for a
  user with no provider.
* `auth.verifyIdToken(idToken)` throws `UnsupportedError` on this REST
  implementation: there is no server-side verification here. Verify tokens on
  a backend with the admin SDK (`tekartik_firebase_auth_node`) or against
  Google's public keys; do not trust a token just because it decodes.
* Bearer headers: `getAuthorizationHeader(token)` builds `'Bearer <token>'`
  and `parseAuthorizationHeaderToken(authorization)` returns the second
  space-separated part. `parseAuthorizationHeaderToken` throws a
  `RangeError` on a header without a space — guard it on a server before
  calling it.
* Never log, print or persist an id token or a refresh token in clear outside
  of a `FirebaseRestAuthPersistence` store; they are bearer credentials.

## Examples

### Renew tokens by hand and handle an expired session

```dart
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';

/// Returns a usable id token, renewing [tokens] in place when needed.
/// Returns null when the user has to sign in again.
Future<String?> freshIdToken(
  RestAuthTokens tokens, {
  required String apiKey,
}) async {
  if (!tokens.isExpiring() || !tokens.canRefresh) {
    return tokens.isExpired() ? null : tokens.idToken;
  }
  var refresher = RestAuthTokenRefresher(apiKey: apiKey);
  try {
    tokens.update(await refresher.refresh(tokens.refreshToken!));
    return tokens.idToken;
  } on RestAuthTokenRefreshException catch (e) {
    if (e.isSessionExpired) {
      return null; // sign out, ask for credentials again
    }
    rethrow; // network/server: keep the session, retry later
  }
}
```

### Tokens from a sign-in response, and inspecting a raw jwt

```dart
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';

RestAuthTokens fromIdentityToolkit(Map<String, Object?> response) {
  return RestAuthTokens.fromSignIn(
    idToken: response['idToken'] as String,
    refreshToken: response['refreshToken'] as String?,
    expiresIn: response['expiresIn']?.toString(),
  );
}

/// Unverified: reads the `exp` claim only, null when not a jwt.
bool looksExpired(String idToken) {
  var expiration = idTokenExpiration(idToken);
  return expiration != null && !DateTime.now().isBefore(expiration);
}
```

### Calling your own API as the signed-in user

```dart
import 'package:http/http.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';

Future<String> callApi(FirebaseAuthRest auth, Uri uri) async {
  var user = await auth.onCurrentUser.first;
  if (user == null) {
    throw StateError('not signed in');
  }
  var idToken = await (user as UserInfoWithIdToken).getIdToken();
  var client = Client();
  try {
    var response = await client.get(
      uri,
      headers: {'Authorization': getAuthorizationHeader(idToken)},
    );
    if (response.statusCode == 401) {
      // Token refused: force a renewal and let the caller retry.
      await (user as UserInfoWithIdToken).getIdToken(forceRefresh: true);
    }
    return response.body;
  } finally {
    client.close();
  }
}
```

### Reading the bearer token on the server side

```dart
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';

/// The raw id token of a request, null when the header is missing or
/// malformed. Still unverified: check it against Google's keys or the admin
/// SDK before trusting its claims.
String? requestIdToken(Map<String, String> headers) {
  var authorization = headers['Authorization'] ?? headers['authorization'];
  if (authorization == null || !authorization.contains(' ')) {
    return null;
  }
  return parseAuthorizationHeaderToken(authorization);
}
```

### Refresher against the auth emulator, with an injected client

```dart
import 'package:http/http.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';

RestAuthTokenRefresher emulatorRefresher({Client Function()? clientFactory}) {
  var refresher = RestAuthTokenRefresher(
    apiKey: 'dummy',
    rootUrl: 'http://localhost:9099/',
    clientFactory: clientFactory,
  );
  print('token endpoint: ${refresher.uri}');
  return refresher;
}
```
