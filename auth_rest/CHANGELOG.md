# 0.9.3

- `listUsers` implemented (identity toolkit `downloadAccount`), and
  `getUserByEmail` (`getAccountInfo` by email): both need admin credentials,
  an app initialized with a service account.
- `FirebaseAuthServiceRest(isAdmin: true)` and `firebaseAuthServiceRestAdmin`,
  a service reporting `supportsListUsers` for such an app. The default service
  still reports `false`.
- A `UserRecord` now carries `disabled`, `phoneNumber`, `metadata` (creation
  and last sign-in times), `customClaims` and `tokensValidAfterTime`, and
  `isAnonymous` for an account without provider, email nor phone.

# 0.9.2

- Renew the id token of the built-in (email/password, anonymous) provider: the
  refresh token and the expiration are kept in the persisted session, an
  expiring token is renewed on restore and before a request (`LoggedInClient`),
  and a request refused with 401 is retried once after a renewal. A session the
  api refuses to renew signs the user out.
- `RestAuthTokens`, `RestAuthTokenRefresher` and `idTokenExpiration` exported.
- `AuthProviderRest.getIdToken` implemented for the built-in provider.

# 0.9.1

- `sendPasswordResetEmail` (identity toolkit v1 `sendOobCode`).
