import 'package:http/http.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest_token.dart';
import 'package:tekartik_firebase_auth_rest/src/user_credential_rest.dart';

import 'identitytoolkit/v3.dart' as identitytoolkit_v3;

/// Internal request implementation
class RequestImpl extends BaseRequest {
  final Stream<List<int>> _stream;

  /// Create request
  RequestImpl(super.method, super.url, [Stream<List<int>>? stream])
    : _stream = stream ?? const Stream.empty();

  @override
  ByteStream finalize() {
    super.finalize();
    return ByteStream(_stream);
  }
}

/// Api key client
class ApiKeyClient extends BaseClient {
  /// The api key
  final String apiKey;

  /// The inner client
  final Client inner;

  /// Create api key client
  ApiKeyClient({Client? inner, required this.apiKey})
    : inner = inner ?? Client();

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    var existing = request;
    var stream = existing.finalize();
    var queryParam = Map<String, String>.from(existing.url.queryParameters);

    queryParam['key'] = apiKey;
    var newRequest = RequestImpl(
      existing.method,
      existing.url.replace(queryParameters: queryParam),
      stream,
    );
    newRequest.headers.addAll(existing.headers);

    return inner.send(newRequest);
  }
}

/// Renews the id token of a [LoggedInClient]: when [force], even if it is not
/// expiring yet (the server refused it).
typedef LoggedInClientTokenRefresh = Future<void> Function({bool force});

/// Authenticated client: sends the id token of [userCredential] as bearer.
///
/// With [refreshToken] set and a credential that can be renewed
/// ([RestAuthTokens.canRefresh]), the token is renewed before a request when
/// it is expiring, and once more, followed by a retry, when the server answers
/// 401 anyway. Requests with a body larger than [maxRetryBodyLength], or of
/// unknown length, are streamed through and not retried.
class LoggedInClient extends BaseClient {
  /// Bodies up to this size are buffered so the request can be retried.
  static const int maxRetryBodyLength = 4 * 1024 * 1024;

  /// The user credential
  final UserCredentialRest userCredential;

  /// The inner client
  final Client inner;

  /// Renews the token, null when the credential cannot be renewed.
  final LoggedInClientTokenRefresh? refreshToken;

  /// Create logged in client
  LoggedInClient({
    Client? inner,
    required this.userCredential,
    this.refreshToken,
  }) : inner = inner ?? Client();

  LoggedInClientTokenRefresh? get _refresh =>
      (userCredential.tokens?.canRefresh ?? false) ? refreshToken : null;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    var refresh = _refresh;
    if (refresh != null && (userCredential.tokens?.isExpiring() ?? false)) {
      await refresh(force: false);
    }
    var stream = request.finalize();
    var length = request.contentLength;
    if (refresh == null || length == null || length > maxRetryBodyLength) {
      return inner.send(_newRequest(request, stream));
    }
    var bytes = await stream.toBytes();
    var response = await inner.send(_newRequest(request, Stream.value(bytes)));
    if (response.statusCode == 401) {
      // The token was refused (revoked, clock skew...): renew it once and
      // retry. A refused renewal throws and signs the user out.
      try {
        await response.stream.drain<void>();
      } catch (_) {
        // The body of the error does not matter.
      }
      await refresh(force: true);
      response = await inner.send(_newRequest(request, Stream.value(bytes)));
    }
    return response;
  }

  /// A copy of [existing] with [stream] as body and the current id token.
  BaseRequest _newRequest(BaseRequest existing, Stream<List<int>> stream) {
    var newRequest = RequestImpl(existing.method, existing.url, stream);
    newRequest.headers.addAll(existing.headers);
    newRequest.headers['Authorization'] = 'Bearer ${userCredential.idToken}';
    return newRequest;
  }
}

/// User credential email password implementation
class UserCredentialEmailPasswordRestImpl extends UserCredentialRestImpl {
  /// The sign in response
  final identitytoolkit_v3.VerifyPasswordResponse signInResponse;

  /// Create user credential, keeping the refresh token and the expiration of
  /// the response so the id token can be renewed.
  UserCredentialEmailPasswordRestImpl(
    this.signInResponse,
    super.credential,
    super.user,
  ) : super(
        tokens: RestAuthTokens.fromSignIn(
          idToken: signInResponse.idToken!,
          refreshToken: signInResponse.refreshToken,
          expiresIn: signInResponse.expiresIn,
        ),
      );

  @override
  String toString() => '$user $credential';

  @override
  String get idToken => tokens!.idToken;
}
