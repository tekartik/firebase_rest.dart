import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_rest/storage_rest.dart';

/// Create new firestore client without auth
Storage noAuthStorageRest({required String? projectId}) {
  var firebase = firebaseRest;
  var app = firebase.initializeApp(
      options: AppOptionsRest(client: httpClientFactory.newClient())
        ..projectId = projectId);
  var storage = storageServiceRest.storage(app);
  return storage;
}
