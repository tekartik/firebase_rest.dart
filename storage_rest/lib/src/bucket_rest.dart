import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_rest/src/storage_rest_impl.dart';

import 'file_rest.dart';

class BucketRest with BucketMixin implements Bucket {
  final StorageRest storageRest;
  @override
  final String name;

  BucketRest(this.storageRest, this.name);

  StorageRestImpl get impl => storageRest as StorageRestImpl;

  @override
  Future<bool> exists() => impl.bucketExists(this);
  @override
  File file(String path) => FileRest(this, path);

  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]) =>
      impl.getFiles(this, options ?? GetFilesOptions());
}
