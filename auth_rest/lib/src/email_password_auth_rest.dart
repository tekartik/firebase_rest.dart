import 'package:http/http.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart';

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
class ApiKeyClientClient extends BaseClient {
  /// The api key
  final String apiKey;

  /// The inner client
  final Client inner;

  /// Create api key client
  ApiKeyClientClient({Client? inner, required this.apiKey})
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

/// Authenticated client
class LoggedInClient extends BaseClient {
  /// The user credential
  final UserCredentialRestImpl userCredential;

  /// The inner client
  final Client inner;

  /// Create logged in client
  LoggedInClient({Client? inner, required this.userCredential})
    : inner = inner ?? Client();

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    /*
    var existing = request;
    var stream = existing.finalize();
    var bytes = await stream.toBytes();
    var queryParam = Map<String, String>.from(existing.url.queryParameters);
    var newRequest = Request(
        existing.method, existing.url.replace(queryParameters: queryParam));
    newRequest.headers.addAll(existing.headers);
    newRequest.bodyBytes = bytes;

    return newRequest.send();

     */ /*
    request.headers['Authorization'] =
        'Bearer ${userCredential.signInResponse.idToken}';
    return inner.send(request);*/
    var existing = request;

    var stream = existing.finalize();
    var newRequest = RequestImpl(existing.method, existing.url, stream);
    newRequest.headers.addAll(existing.headers);
    newRequest.headers['Authorization'] = 'Bearer ${userCredential.idToken}';

    return inner.send(newRequest);
  }
}

/// User credential email password implementation
class UserCredentialEmailPasswordRestImpl extends UserCredentialRestImpl {
  /// The sign in response
  final identitytoolkit_v3.VerifyPasswordResponse signInResponse;

  /// Create user credential
  UserCredentialEmailPasswordRestImpl(
    this.signInResponse,
    super.credential,
    super.user,
  );

  @override
  String toString() => '$user $credential';

  @override
  String get idToken => signInResponse.idToken!;
}
