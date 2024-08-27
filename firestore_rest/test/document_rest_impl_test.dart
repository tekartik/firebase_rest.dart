import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_rest/src/document_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/import.dart';
import 'package:tekartik_firebase_firestore_rest/src/patch_document_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/read_document_rest_impl.dart';
import 'package:test/test.dart';

import 'no_auth_firestore.dart'; // ignore: implementation_imports

class FirestoreDocumentContextMock implements FirestoreDocumentContext {
  @override
  String getDocumentName(String path) => path;

  @override
  String? getDocumentPath(String? name) => name;

  // Unused
  late final _firestore =
      noAuthFirestoreRest(projectId: 'dummy') as FirestoreRestImpl;

  @override
  FirestoreRestImpl get impl => _firestore;
}

final FirestoreDocumentContextMock firestoreMock =
    FirestoreDocumentContextMock();

Future main() async {
  group('document', () {
    test('patch', () {
      var patchDocument = UpdateDocument(firestoreMock, {});
      expect(patchDocument.fields, isEmpty);
      var data = {'test': 1};
      patchDocument = UpdateDocument(firestoreMock, data);
      var readDocument = ReadDocument(firestoreMock, patchDocument.document);
      expect(patchDocument.fields!['test']!.integerValue, '1');
      expect(readDocument.data, data);
    });
    test('updateSubfield', () {
      var data = {'sub.test': 1};
      var patchDocument = UpdateDocument(firestoreMock, data);
      var readDocument = ReadDocument(firestoreMock, patchDocument.document);
      //expect(patchDocument.fields['test'].integerValue, '1');
      // devPrint(patchDocument);
      expect(patchDocument.fields!.keys, ['sub']);
      expect(patchDocument.fieldPaths, ['sub.test']);
      expect(readDocument.data, {
        'sub': {'test': 1}
      });
    });

    test('updateSubfield', () {
      var data = {'sub.test': 1, 'sub.sub.test': 2};
      var patchDocument = UpdateDocument(firestoreMock, data);
      var readDocument = ReadDocument(firestoreMock, patchDocument.document);
      //expect(patchDocument.fields['test'].integerValue, '1');
      // devPrint(patchDocument);
      expect(patchDocument.fields!.keys, ['sub']);
      expect(patchDocument.fieldPaths, ['sub.test', 'sub.sub.test']);
      expect(readDocument.data, {
        'sub': {
          'test': 1,
          'sub': {'test': 2}
        }
      });
    });
    test('setSubfield', () {
      var data = {'sub.test': 1};
      var patchDocument = SetDocument(firestoreMock, data);
      var readDocument = ReadDocument(firestoreMock, patchDocument.document);
      //expect(patchDocument.fields['test'].integerValue, '1');
      // devPrint(patchDocument);
      expect(patchDocument.fields!.keys, ['sub.test']);
      expect(patchDocument.fieldPaths, isNull);
      expect(readDocument.data, data);
    });

    test('SetMergedDocument', () {
      var writeDoc = SetMergedDocument(firestoreMock, {
        'f1': 1,
      });
      expect(writeDoc.fieldPaths, ['f1']);
      writeDoc = SetMergedDocument(firestoreMock, {
        'f1': {'f2': 2},
      });
      expect(writeDoc.fieldPaths, ['f1.f2']);
      var map = {
        'f1': 1,
        'f2': {'f3': 2},
        'f4': {
          'f5': {'f6': 6}
        },
      };
      writeDoc = SetMergedDocument(firestoreMock, map);
      expect(writeDoc.fieldPaths, ['f1', 'f2.f3', 'f4.f5.f6']);
      var readDocument = ReadDocument(firestoreMock, writeDoc.document);
      expect(readDocument.data, map);

      map = {'sub.field': 1};
      writeDoc = SetMergedDocument(firestoreMock, {'sub.field': 1});
      expect(writeDoc.fieldPaths, ['`sub.field`']);
      readDocument = ReadDocument(firestoreMock, writeDoc.document);
      expect(readDocument.data, map);
    });

    test('set', () {
      var patchDocument = SetDocument(firestoreMock, {});
      expect(patchDocument.fields, isEmpty);
      var data = {'test': 1};
      patchDocument = SetDocument(firestoreMock, data);
      var readDocument = ReadDocument(firestoreMock, patchDocument.document);
      expect(patchDocument.fields!['test']!.integerValue, '1');
      expect(readDocument.data, data);
      data = {'other_test': 2};
      patchDocument = SetDocument(firestoreMock, data);
      readDocument = ReadDocument(firestoreMock, patchDocument.document);
      expect(patchDocument.fields!['other_test']!.integerValue, '2');
      expect(patchDocument.fields!.keys, ['other_test']);
      expect(patchDocument.fieldPaths, null);
      expect(readDocument.data, data);
    });
    test('patchDelete', () {
      var patchDocument =
          UpdateDocument(firestoreMock, {'test': FieldValue.delete});
      expect(patchDocument.fields, isEmpty);
      expect(patchDocument.fieldPaths, ['test']);

      patchDocument = UpdateDocument(firestoreMock, {'test2': 1});
      expect(patchDocument.fields!['test2']!.integerValue, '1');
      expect(patchDocument.fields!.keys, ['test2']);
      expect(patchDocument.fieldPaths, ['test2']);

      patchDocument = UpdateDocument(
          firestoreMock, {'test': FieldValue.delete, 'test2': 1});
      expect(patchDocument.fields!['test2']!.integerValue, '1');
      expect(patchDocument.fieldPaths, ['test', 'test2']);
    });

    test('subField', () {
      var patchDocument = UpdateDocument(firestoreMock, {'test.sub': 1});
      // devPrint(jsonPretty(patchDocument.document.toJson()));
      expect(
          patchDocument.fields!['test']!.mapValue!.fields!['sub']!.integerValue,
          '1');
      expect(patchDocument.fieldPaths, ['test.sub']);
    });

    test('runQueryFixed', () {
      var json = [
        {
          'document': {
            'createTime': '2018-10-27T05:34:53.459862Z',
            'fields': {
              'sub': {
                'mapValue': {
                  'fields': {
                    'value': {'stringValue': 'b'}
                  }
                }
              },
              'date': {'timestampValue': '1970-01-01T00:00:00.002Z'},
              'value': {'integerValue': '1'},
              'array': {
                'arrayValue': {
                  'values': [
                    {'integerValue': '3'},
                    {'integerValue': '4'}
                  ]
                }
              }
            },
            'name':
                'projects/tekartik-free-dev/databases/(default)/documents/tests/tekartik_firebase/tests/collection_test/many/one',
            'updateTime': '2018-10-27T05:34:53.459862Z'
          },
          'readTime': '2019-11-02T15:30:32.293753Z'
        },
        {
          'document': {
            'createTime': '2018-10-27T05:34:53.681486Z',
            'fields': {
              'sub': {
                'mapValue': {
                  'fields': {
                    'value': {'stringValue': 'a'}
                  }
                }
              },
              'date': {'timestampValue': '1970-01-01T00:00:00.001Z'},
              'value': {'integerValue': '2'}
            },
            'name':
                'projects/tekartik-free-dev/databases/(default)/documents/tests/tekartik_firebase/tests/collection_test/many/two',
            'updateTime': '2018-10-27T05:34:53.681486Z'
          },
          'readTime': '2019-11-02T15:30:32.293753Z'
        }
      ];

      // ignore: omit_local_variable_types
      RunQueryResponse response =
          json.map((e) => RunQueryResponseElement.fromJson(e)).toList();
      expect(response.length, 2);
    });
  });
}
