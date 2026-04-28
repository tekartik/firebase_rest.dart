import 'package:tekartik_firebase_storage/utils/link.dart';
import 'package:tekartik_firebase_storage_rest/src/storage_rest_impl.dart';
import 'package:tekartik_firebase_storage_rest/storage_json.dart';

abstract class ReferenceRest implements Reference {}

class ReferenceRestImpl with ReferenceMixin implements ReferenceRest {
  final StorageRestImpl storage;
  final StorageFileRef fileRef;

  ReferenceRestImpl({required this.storage, required this.fileRef});
  @override
  Future<String> getDownloadUrl() async {
    var api = UnauthenticatedStorageApi(
      appOptions: storage.appRest.options,
      client: null,
    );
    return api.getDownloadUrl(fileRef);
  }

  @override
  String toString() => 'ReferenceRes($fileRef)';
}
