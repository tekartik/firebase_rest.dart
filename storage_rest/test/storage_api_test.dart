import 'package:googleapis/storage/v1.dart' as api;
import 'package:tekartik_firebase_storage_rest/src/import.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

// Future<List<String>> get
Future main() async {
  final context = await storageRestSetup();
  // AppOptions accessTokenAppOptions;
  if (context != null) {
    /*
    accessTokenAppOptions = getAppOptionsFromAccessToken(
        Client(), context.accessToken.data,
        projectId: context.options.projectId, scopes: firebaseBaseScopes);
     */
  }
  // print(context);
  group('rest', () {
    test('basic_googleapis', () async {
      var storageApi = api.StorageApi(context!.authClient!);

      // curl "https://firestore.googleapis.com/v1beta1/projects/tekartik-free-dev/databases/(default)/documents/tests/data-types"
      // curl "https://firestore.googleapis.com/projects/tekartik-free-dev/databases/(default)/documents/tests/data-types"
      // ignore: unused_local_variable
      var bucket = appOptionsGetStorageBucket(context.options!);

      print(jsonPretty('bucket: $bucket'));
      var data = await storageApi.objects.list(bucket);
      // print(jsonPretty(data.toJson()));
      // ignore: unused_local_variable
      for (var item in data.items!) {
        print('${item.kind}: ${item.name}');
      }
      //data.items!.forEach((element) {
      //  print('${element.kind}: ${element.name}');
      //});

      if (data.items!.isNotEmpty) {
        var item = data.items!.first;
        var meta = await storageApi.objects.get(item.bucket!, item.name!);
        if (meta is api.Object) {
          print(jsonPretty(meta.toJson()));
        }
      }
    });

    /*
    test('access_token', () async {
      var app = firebaseRest.initializeApp(
          options: accessTokenAppOptions, name: 'access_token');
      var firestore = firestoreServiceRest.firestore(app);
      var snapshot = await firestore.doc('validate_user_access/_dummy').get();
      expect(snapshot.exists, isFalse);
    });

     */
  }, skip: context == null);

  tearDownAll(() {
    context?.authClient?.close();
  });
}
