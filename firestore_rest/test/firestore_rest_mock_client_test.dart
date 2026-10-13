// Offline tests of the requests sent, through a mock http client.
import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

const _jsonHeaders = {'content-type': 'application/json'};

void main() {
  var appIndex = 0;

  /// Firestore sending its requests to [handler].
  FirestoreRestImpl newFirestore(
    Future<Response> Function(Request request) handler,
  ) {
    var app = firebaseRest.initializeApp(
      options: AppOptionsRest(client: MockClient(handler))..projectId = 'p',
      name: 'mock_client_${++appIndex}',
    );
    return firestoreServiceRest.firestore(app) as FirestoreRestImpl;
  }

  group('restEscapeKey', () {
    test('simple names', () {
      expect(restEscapeKey('a'), 'a');
      expect(restEscapeKey('_a1'), '_a1');
    });
    test('quoted names', () {
      expect(restEscapeKey('1x'), '`1x`');
      expect(restEscapeKey('my-field'), '`my-field`');
      expect(restEscapeKey('a.b'), '`a.b`');
      expect(restEscapeKey('a b'), '`a b`');
      expect(restEscapeKey('é'), '`é`');
      expect(restEscapeKey(''), '``');
      expect(restEscapeKey('a`b'), r'`a\`b`');
      expect(restEscapeKey(r'a\b'), r'`a\\b`');
    });
  });

  group('writes', () {
    late List<Request> requests;
    late FirestoreRestImpl firestore;
    late DocumentReference ref;
    setUp(() {
      requests = [];
      firestore = newFirestore((request) async {
        requests.add(request);
        return Response('{"writeResults":[]}', 200, headers: _jsonHeaders);
      });
      ref = firestore.doc('c/d');
    });

    /// The single write of the single commit request sent.
    Map<String, Object?> sentWrite() {
      expect(requests, hasLength(1));
      var request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, endsWith(':commit'));
      var body = jsonDecode(request.body) as Map;
      var writes = body['writes'] as List;
      expect(writes, hasLength(1));
      return (writes.single as Map).cast<String, Object?>();
    }

    Map<String, Object?>? sentFields() =>
        ((sentWrite()['update'] as Map)['fields'] as Map?)
            ?.cast<String, Object?>();

    Object? sentMask() => (sentWrite()['updateMask'] as Map?)?['fieldPaths'];

    test('set merge empty', () async {
      await ref.set({}, SetOptions(merge: true));
      // An empty mask: no field written (the document is not cleared).
      expect(sentMask(), isEmpty);
      expect(sentFields(), isEmpty);
    });

    test('set merge empty map', () async {
      await ref.set({'a': <String, Object?>{}}, SetOptions(merge: true));
      expect(sentMask(), ['a']);
      expect(sentFields(), {
        'a': {
          'mapValue': {'fields': <String, Object?>{}},
        },
      });
    });

    test('batch set merge empty map', () async {
      await (firestore.batch()
            ..set(ref, {'a': <String, Object?>{}}, SetOptions(merge: true)))
          .commit();
      expect(sentMask(), ['a']);
    });

    test('set merge delete', () async {
      await ref.set({'x': FieldValue.delete}, SetOptions(merge: true));
      expect(sentMask(), ['x']);
      expect(sentFields(), isEmpty);
    });

    test('set merge escaped keys', () async {
      await ref.set({'my-field': 1, 'a.b': 2}, SetOptions(merge: true));
      expect(sentMask(), ['`my-field`', '`a.b`']);
    });

    test('set replaces the document', () async {
      await ref.set({'a': 1});
      expect(sentWrite().containsKey('updateMask'), isFalse);
    });

    test('update empty', () async {
      await ref.update({});
      // Only checks that the document exists, no field written.
      expect(sentWrite()['currentDocument'], {'exists': true});
      expect(sentMask(), isEmpty);
      expect(sentFields(), isEmpty);
    });

    test('update escaped field paths', () async {
      await ref.update({
        'my-field': 1,
        'a.1': 2,
        '`b.c`': 3,
        '1x': FieldValue.increment(1),
      });
      expect(sentMask(), ['`my-field`', 'a.`1`', '`b.c`']);
      expect(sentWrite()['updateTransforms'], [
        {
          'fieldPath': '`1x`',
          'increment': {'integerValue': '1'},
        },
      ]);
    });
  });

  test('query field paths', () async {
    late Map<String, Object?> query;
    var firestore = newFirestore((request) async {
      var body = jsonDecode(request.body) as Map;
      query = (body['structuredQuery'] as Map).cast<String, Object?>();
      return Response('[]', 200, headers: _jsonHeaders);
    });
    await firestore
        .collection('c')
        .where('my-field', isEqualTo: 1)
        .orderBy('a.1x')
        .select(['`b.c`', 'd'])
        .get();
    expect(((query['where'] as Map)['fieldFilter'] as Map)['field'], {
      'fieldPath': '`my-field`',
    });
    expect((query['orderBy'] as List).first, {
      'field': {'fieldPath': 'a.`1x`'},
      'direction': 'ASCENDING',
    });
    expect((query['select'] as Map)['fields'], [
      {'fieldPath': '`b.c`'},
      {'fieldPath': 'd'},
    ]);
  });

  test('errors', () async {
    var firestore = newFirestore(
      (request) async => Response(
        '{"error":{"code":403,"message":"Missing or insufficient permissions.",'
        '"status":"PERMISSION_DENIED"}}',
        403,
        headers: _jsonHeaders,
      ),
    );
    Future<void> expectPermissionDenied(Future<void> Function() action) async {
      try {
        await action();
        fail('should fail');
      } on FirestoreException catch (e) {
        expect(e.code, FirestoreErrorCode.permissionDenied);
      }
    }

    await expectPermissionDenied(
      () => firestore.collection('c').aggregate([AggregateField.count()]).get(),
    );
    await expectPermissionDenied(
      () => firestore.runTransaction((transaction) async {}),
    );
    await expectPermissionDenied(() => firestore.listCollections());
    await expectPermissionDenied(() => firestore.doc('c/d').listCollections());
    await expectPermissionDenied(() => firestore.doc('c/d').set({'a': 1}));
    await expectPermissionDenied(() => firestore.doc('c/d').update({'a': 1}));
  });
}
