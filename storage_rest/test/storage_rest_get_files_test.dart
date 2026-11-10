import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_storage_rest/storage_rest.dart';
import 'package:test/test.dart';

/// A fake storage json api (no network) holding [names] in bucket `b`: pages
/// of `maxResults` objects (1000 by default), the page token being the index
/// of the next object. [requests] gets each request url.
MockClient _fakeStorageApi(List<String> names, List<Uri> requests) {
  return MockClient((request) async {
    requests.add(request.url);
    var parameters = request.url.queryParameters;
    var max = int.tryParse(parameters['maxResults'] ?? '') ?? 1000;
    var start = int.tryParse(parameters['pageToken'] ?? '') ?? 0;
    var end = (start + max).clamp(0, names.length);
    return http.Response(
      jsonEncode({
        'items': [
          for (var name in names.sublist(start, end))
            {
              'name': name,
              'bucket': 'b',
              'size': '1',
              'md5Hash': 'md5',
              'timeCreated': '2020-01-01T00:00:00.000Z',
            },
        ],
        if (end < names.length) 'nextPageToken': '$end',
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
}

void main() {
  test('getFiles pages of maxResults files', () async {
    var names = [for (var i = 0; i < 5; i++) 'dir/f$i'];
    var requests = <Uri>[];
    var app = firebaseRest.initializeApp(
      options: AppOptionsRest(client: _fakeStorageApi(names, requests))
        ..projectId = 'get_files_test',
      name: 'get_files',
    );
    try {
      var bucket = storageServiceRest.storage(app).bucket('b');
      var pages = <List<String>>[];
      GetFilesOptions? query = GetFilesOptions(
        maxResults: 2,
        prefix: 'dir/',
        autoPaginate: false,
      );
      // Bounded: a backend that never ends fails here instead of looping.
      while (query != null && pages.length < 10) {
        var response = await bucket.getFiles(query);
        pages.add(response.files.map((file) => file.name).toList());
        query = response.nextQuery;
      }
      expect(pages, [
        ['dir/f0', 'dir/f1'],
        ['dir/f2', 'dir/f3'],
        ['dir/f4'],
      ]);
      expect(requests.first.queryParameters['maxResults'], '2');
      expect(requests.first.queryParameters['prefix'], 'dir/');

      // A last page of exactly maxResults files: no next query.
      var response = await bucket.getFiles(
        GetFilesOptions(maxResults: 5, autoPaginate: false),
      );
      expect(response.files, hasLength(5));
      expect(response.nextQuery, isNull);
    } finally {
      await app.delete();
    }
  });
}
