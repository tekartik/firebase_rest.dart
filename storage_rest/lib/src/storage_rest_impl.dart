import 'dart:typed_data';

import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis/storage/v1.dart' as api;
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_rest/src/bucket_rest.dart';
import 'package:tekartik_firebase_storage_rest/src/file_rest.dart';
import 'package:tekartik_http/http.dart';

import 'import.dart';

final storageGoogleApisReadWriteScope = api.StorageApi.devstorageReadWriteScope;

abstract class StorageServiceRest extends StorageService {}

/// Storage rest helper.
abstract class StorageRest extends Storage {
  /// Build a storage rest client from an auth client.
  factory StorageRest.fromAuthClient({
    // StorageServiceRest? serviceRest,
    required Client authClient,
  }) {
    return StorageRestImpl.fromAuthClient(
      serviceRest: storageServiceRest,
      authClient: authClient,
    );
  }
}

StorageServiceRest storageServiceRest = StorageServiceRestImpl();

class StorageServiceRestImpl
    with FirebaseProductServiceMixin<FirebaseStorage>
    implements StorageServiceRest {
  @override
  Storage storage(App app) {
    return getInstance(app, () {
      assert(app is FirebaseAppRest, 'invalid firebase app type');
      return StorageRestImpl(this, app as FirebaseAppRest);
    });
  }
}

class StorageRestImpl
    with FirebaseAppProductMixin<FirebaseStorage>, StorageMixin
    implements StorageRest {
  late final StorageServiceRest serviceRest;
  late final FirebaseAppRest appRest;

  Client get authClient => _authClient ?? appRest.apiClient;
  Client? _authClient;
  api.StorageApi? _storageApi;

  api.StorageApi get storageApi => _storageApi ??= api.StorageApi(authClient);

  StorageRestImpl(this.serviceRest, this.appRest);
  StorageRestImpl.fromAuthClient({
    required this.serviceRest,
    required Client authClient,
  }) {
    _authClient = authClient;
  }

  @override
  Bucket bucket([String? name]) => BucketRest(
    this,
    name ??
        appRest.options.storageBucket ??
        '${appRest.options.projectId}.appspot.com',
  );

  Future<bool> fileExists(BucketRest bucket, String path) async {
    try {
      var meta = await storageApi.objects.get(bucket.name, path) as api.Object;
      // devPrint(jsonPretty(meta.toJson()));
      return (meta.id != null);
    } on api.DetailedApiRequestError catch (e) {
      // DetailedApiRequestError(status: 404, message: No such object:xxxx.appspot.com/dummy-file-that-should-not-exists)
      if (e.status == httpStatusCodeNotFound) {
        return false;
      }
      // print(e.runtimeType);
      rethrow;
    }
    // TODO: implement exists
    // return super.exists();
  }

  Future<void> writeFile(
    BucketRest bucket,
    String? path,
    Uint8List bytes,
  ) async {
    var object = api.Object()
      ..name = path
      ..bucket = bucket.name;
    object = await storageApi.objects.insert(
      object,
      bucket.name,
      name: path,
      predefinedAcl: 'publicRead',
      uploadOptions: api.UploadOptions(),
      uploadMedia: api.Media(Stream.fromIterable([bytes]), bytes.length),
    );
  }

  Future<GetFilesResponse> getFiles(
    BucketRest bucket,
    GetFilesOptions options,
  ) async {
    var objects = await storageApi.objects.list(
      bucket.name,
      prefix: options.prefix,
      pageToken: options.pageToken,
    );
    // devPrint(objects.toJson());
    var items = objects.items ?? <api.Object>[];
    var pageToken = objects.nextPageToken;
    GetFilesOptions? nextQuery;
    if (items.isNotEmpty &&
        pageToken != null &&
        items.length != options.maxResults) {
      // max resulsts reach?
      nextQuery = GetFilesOptions(
        prefix: options.prefix,
        autoPaginate: options.autoPaginate,
        maxResults: options.maxResults != null
            ? options.maxResults! - items.length
            : null,
        pageToken: pageToken,
      );
    }
    var response = GetFilesResponseRest()
      ..files = items.map((object) {
        // devPrint(object.toJson());
        return FileRest(
          bucket,
          object.name,
          FileMetadataRest.fromObject(object),
        );
      }).toList()
      ..nextQuery = nextQuery;

    return response;
  }

  List<T> flatten<T>(Iterable<Iterable<T>> list) => [
    for (var sublist in list) ...sublist,
  ];

  Future<Uint8List> readFile(BucketRest bucket, String path) async {
    var media =
        (await storageApi.objects.get(
              bucket.name,
              path,
              downloadOptions: DownloadOptions.fullMedia,
            ))
            as api.Media;
    var listOfList = await media.stream.toList();

    return Uint8List.fromList(flatten(listOfList));
  }

  Future<FileMetadataRest> getMetadata(BucketRest bucket, String path) async {
    var object =
        (await storageApi.objects.get(
              bucket.name,
              path,
              downloadOptions: DownloadOptions.metadata,
            ))
            as api.Object;
    return FileMetadataRest.fromObject(object);
  }

  Future<void> deleteFile(BucketRest bucket, String path) async {
    await storageApi.objects.delete(bucket.name, path);
  }

  Future<bool> bucketExists(BucketRest bucketRest) async {
    try {
      await storageApi.buckets.get(bucketRest.name);
      return true;
    } on api.DetailedApiRequestError catch (e) {
      // DetailedApiRequestError(status: 404, message: The specified bucket does not exist.)
      if (e.status == httpStatusCodeNotFound) {
        return false;
      }
      rethrow;
    }
  }

  @override
  FirebaseApp get app => appRest;

  @override
  FirebaseStorageService get service => serviceRest;
}

class GetFilesResponseRest implements GetFilesResponse {
  @override
  late List<File> files;

  @override
  GetFilesOptions? nextQuery;
}
