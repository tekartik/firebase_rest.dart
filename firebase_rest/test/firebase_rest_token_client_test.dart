import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

class _TokenClient extends BaseClient implements FirebaseRestTokenClient {
  var token = 'token1';
  var forcedRefreshCount = 0;

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      forcedRefreshCount++;
      token = 'token${forcedRefreshCount + 1}';
    }
    return token;
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) =>
      throw UnimplementedError();
}

void main() {
  group('firebaseRestClientAccessToken', () {
    test('none', () async {
      expect(await firebaseRestClientAccessToken(null), isNull);
      expect(await firebaseRestClientAccessToken(Client()), isNull);
    });
    test('token client', () async {
      var client = _TokenClient();
      expect(await firebaseRestClientAccessToken(client), 'token1');
      expect(
        await firebaseRestClientAccessToken(client, forceRefresh: true),
        'token2',
      );
      expect(client.forcedRefreshCount, 1);
    });
    test('auth client', () async {
      var client = authenticatedClient(
        Client(),
        AccessCredentials(
          AccessToken(
            'Bearer',
            'access_token',
            DateTime.now().toUtc().add(const Duration(hours: 1)),
          ),
          null,
          [],
        ),
      );
      expect(await firebaseRestClientAccessToken(client), 'access_token');
    });
  });
}
