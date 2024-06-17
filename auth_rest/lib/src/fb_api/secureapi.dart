import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth_rest/src/import.dart';

@Deprecated('do not use')
class SecureTokenApi {
  AuthClient client;
  final String apiKey;

  SecureTokenApi({required this.apiKey, required this.client});
  Future<String> getIdToken({bool? forceRefresh}) async {
    late String body;

    var uri = Uri.parse('securetoken.googleapis.com/v1/token?key=$apiKey');
    if (client.credentials.refreshToken != null) {
      body = json.encode({
        'grant_type': 'refresh_token',
        'refresh_token': client.credentials.refreshToken!
      });
    } else {
      body = json.encode({});
    }
    var text = await httpClientRead(client, httpMethodPost, uri,
        body: body); //securetoken.googleapis.com/v1/token?key=$apiKey
    // ignore: deprecated_member_use
    devPrint(text);
    //var map = jsonDecode(text);
    throw UnsupportedError('not working');
  }
}
