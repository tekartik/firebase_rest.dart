import 'package:http/http.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart';

class RequestImpl extends BaseRequest {
  final Stream<List<int>> _stream;

  RequestImpl(super.method, super.url, [Stream<List<int>>? stream])
    : _stream = stream ?? const Stream.empty();

  @override
  ByteStream finalize() {
    super.finalize();
    return ByteStream(_stream);
  }
}

class EmailPasswordLoginClient extends BaseClient {
  final String apiKey;
  final Client inner;

  EmailPasswordLoginClient({Client? inner, required this.apiKey})
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
class EmailPasswordLoggedInClient extends BaseClient {
  final UserCredentialEmailPasswordRestImpl userCredential;
  final Client inner;

  EmailPasswordLoggedInClient({Client? inner, required this.userCredential})
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
    newRequest.headers['Authorization'] =
        'Bearer ${userCredential.signInResponse.idToken}';

    return inner.send(newRequest);
  }
}
