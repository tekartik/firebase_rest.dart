@TestOn('vm')
library;

import 'package:tekartik_firebase_storage/utils/link.dart';
import 'package:tekartik_firebase_storage_rest/storage_json.dart';
import 'package:test/test.dart';

Future main() async {
  group('json', () {
    test('list response', () {
      var map = {
        'prefixes': <Object?>[],
        'items': [
          {'name': 'test.json', 'bucket': 'test.appspot.com'},
        ],
      };
      var response = GsReferenceListResponse()..fromMap(map);
      expect(response.items![0].name, 'test.json');
      expect(response.items![0].bucket, 'test.appspot.com');
    });
    test('getDownloadUrl', () async {
      var api = UnauthenticatedStorageApi(
        client: null,
        appOptions: AppOptions(
          projectId: 'test',
          storageBucket: 'test.appspot.com',
        ),
      );
      var storageFileRef = StorageFileRef('test.appspot.com', 'path/to/file');
      var url = api.getDownloadUrl(storageFileRef);
      expect(
        url,
        'https://firebasestorage.googleapis.com/v0/b/test.appspot.com/o/path%2Fto%2Ffile?alt=media',
      );
    });
  });
}
