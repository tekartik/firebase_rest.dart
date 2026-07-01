import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_rest/src/storage_rest_impl.dart';

import 'file_rest.dart';

/// Rest bucket implementation.
class BucketRest with BucketMixin implements Bucket {
  /// Owning storage instance.
  final FirebaseStorageRest storageRest;
  @override
  final String name;

  /// Rest bucket implementation.
  BucketRest(this.storageRest, this.name);

  /// Impl access.
  StorageRestImpl get impl => storageRest as StorageRestImpl;

  @override
  Future<bool> exists() => impl.bucketExists(this);
  @override
  File file(String path) => FileRest(this, path);

  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]) =>
      impl.getFiles(this, options ?? GetFilesOptions());
}
