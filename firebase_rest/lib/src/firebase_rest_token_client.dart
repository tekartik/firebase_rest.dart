import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';

/// A client that authenticates its requests with a bearer token it can hand
/// out (a signed in firebase user and its id token), for the services that
/// cannot send their requests through the client itself, such as the
/// firestore listen gRPC channel.
abstract interface class FirebaseRestTokenClient {
  /// The current bearer token, renewed first when it is expiring or when
  /// [forceRefresh] (the server refused it).
  Future<String?> getAccessToken({bool forceRefresh = false});
}

/// The bearer token [client] sends, null when it sends none (no client, a
/// plain or an api key client: unauthenticated requests).
///
/// A [FirebaseRestTokenClient] (a signed in user) is asked for its token,
/// renewed when expiring or when [forceRefresh]. An [AuthClient] (service
/// account, google oauth) gives its current access token: it renews it
/// itself on its next request, [forceRefresh] has no effect there.
Future<String?> firebaseRestClientAccessToken(
  Client? client, {
  bool forceRefresh = false,
}) async {
  if (client case FirebaseRestTokenClient tokenClient) {
    return await tokenClient.getAccessToken(forceRefresh: forceRefresh);
  }
  if (client is AuthClient) {
    return client.credentials.accessToken.data;
  }
  return null;
}
