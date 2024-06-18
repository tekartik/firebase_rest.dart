@TestOn('vm')
library tekartik_firebase_storage_rest.test.storage_json_io_test;

import 'dart:io';

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_storage_rest/storage_json.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  final context = await storageRestSetup();

  group('rest', () {
    var supported = false;
    late UnauthenticatedStorageApi api;
    // print(context);

    setUpAll(() async {
      api = UnauthenticatedStorageApi(
          appOptions: context!.options, client: context.authClient);
      try {
        print('Testing storage support');
        await api.list(prefix: '_dummy_123456789_that_never_exists/');
        print('Storage test supported');
        supported = true;
        // print(result);
      } catch (e, st) {
        stderr.writeln('(TMP CAN FAIL) api.list failed $e');
        stderr.writeln(st);
      }
    });

    test('list all', () async {
      if (supported) {
        await api.list();
        // print(result);
      }
    });

    GsReference? firstReference;
    Future<bool> initFirst() async {
      if (supported) {
        if (firstReference == null) {
          var result = await api.list();
          if (result.items!.isNotEmpty) {
            firstReference = result.items!.first;
          }
          print('first: $firstReference');
        }
      }
      return firstReference != null;
    }

    test('list prefixed', () async {
      if (supported) {
        var result = await api.list(prefix: 'slides/');
        print(result);
      }
    });
    test('get meta', () async {
      if (await initFirst()) {
        var storageBucket = api.storageBucket;
        expect(api.getFileUrl(firstReference!.name!),
            'https://firebasestorage.googleapis.com/v0/b/$storageBucket/o/${Uri.encodeComponent(firstReference!.name!)}');
        expect(api.getMediaUrl(firstReference!.name!),
            'https://firebasestorage.googleapis.com/v0/b/$storageBucket/o/${Uri.encodeComponent(firstReference!.name!)}?alt=media');
        try {
          var result = await api.getInfo(firstReference!);
          print(result);
        } catch (e) {
          print('error 400 might happen');
          print('api.getInfo failed $e');
        }
      }
    });
  }, skip: context == null);
}
