@TestOn('vm')
library;

import 'package:tekartik_firebase_storage_rest/storage_json.dart';
import 'package:test/test.dart';

Future main() async {
  group('json', () {
    test('list response', () {
      var map = {
        'prefixes': <Object?>[],
        'items': [
          {'name': 'test.json', 'bucket': 'test.appspot.com'}
        ]
      };
      var response = GsReferenceListResponse()..fromMap(map);
      expect(response.items![0].name, 'test.json');
      expect(response.items![0].bucket, 'test.appspot.com');
    });
  });
}
