import 'package:tekartik_firebase_storage/utils/link.dart';
import 'package:tekartik_firebase_storage_rest/src/storage_rest_impl.dart';
import 'package:tekartik_firebase_storage_rest/storage_json.dart';

/// Rest reference.
abstract class ReferenceRest implements Reference {}

/// Rest reference implementation.
class ReferenceRestImpl with ReferenceMixin implements ReferenceRest {
  /// Owning storage instance.
  final StorageRestImpl storage;

  /// The referenced file.
  final StorageFileRef fileRef;

  /// Rest reference implementation.
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
