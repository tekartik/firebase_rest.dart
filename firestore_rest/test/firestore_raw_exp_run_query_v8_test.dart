// ignore_for_file: avoid_print

import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('runQuery', () async {
    var client = Client();
    try {
      // Temp no auth query
      var path =
          'projects/tekartik-net-dev/databases/(default)/documents/tests/tekartik_firebase/tests/a2OZAEskPoMDERpjLEc4/et1fJO9Bk8iGu9MaMpXh';
      var firestoreApi = FirestoreApi(client);
      // Run query
      var query = RunQueryRequest()
        ..structuredQuery = StructuredQuery(
            from: [CollectionSelector()..collectionId = p.url.basename(path)]);
      var response = await firestoreApi.projects.databases.documents
          .runQuery(query, p.url.dirname(path));
      // There should be 2 documents
      print(response.map((element) => element.document?.toJson()).join('\n'));
    } finally {
      client.close();
    }
  });
}
