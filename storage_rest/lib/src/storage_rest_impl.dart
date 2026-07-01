import 'dart:typed_data';

import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis/storage/v1.dart' as api;
import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage/utils/content_type.dart';
import 'package:tekartik_firebase_storage/utils/link.dart';
import 'package:tekartik_firebase_storage_rest/src/bucket_rest.dart';
import 'package:tekartik_firebase_storage_rest/src/file_rest.dart';
import 'package:tekartik_firebase_storage_rest/src/reference_rest.dart';
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

  /// Changes this instance to point to a Storage emulator running locally.
  ///
  /// Set the [host] and [port] of the local emulator, such as "localhost"
  /// with port 9199.
  ///
  /// Note: Must be called immediately, prior to accessing storage methods.
  /// Do not use with production credentials as emulator traffic is not
  /// encrypted.
  Future<void> useStorageEmulator(String host, int port);
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

  /// Root url override, set when pointing to a Storage emulator.
  String? rootUrl;

  api.StorageApi get storageApi => _storageApi ??= rootUrl != null
      ? api.StorageApi(authClient, rootUrl: rootUrl!)
      : api.StorageApi(authClient);

  StorageRestImpl(this.serviceRest, this.appRest);
  StorageRestImpl.fromAuthClient({
    required this.serviceRest,
    required Client authClient,
  }) {
    _authClient = authClient;
  }

  @override
  Future<void> useStorageEmulator(String host, int port) async {
    rootUrl = 'http://$host:$port/';
    _storageApi = null;
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
    String path,
    Uint8List bytes,
    StorageUploadFileOptions? options,
  ) async {
    var object = api.Object()
      ..name = path
      ..bucket = bucket.name;
    var contentType =
        options?.contentType ??
        firebaseStorageContentTypeFromFilename(url.basename(path));
    var stream = Stream.fromIterable([bytes]);
    var media = contentType != null
        ? api.Media(stream, bytes.length, contentType: contentType)
        : api.Media(stream, bytes.length);

    // The Storage emulator does not correctly parse multipart upload
    // bodies (the format used by [api.UploadOptions]), nor does it expose
    // the resumable upload path used by the googleapis client
    // (`/resumable/upload/...`). Perform a manual resumable upload against
    // the emulator's `/upload/storage/v1/b/{bucket}/o` route instead.
    if (rootUrl != null) {
      object.contentType = contentType;
      object = await _writeFileEmulator(bucket, path, bytes, object, media);
    } else {
      object = await storageApi.objects.insert(
        object,
        bucket.name,
        name: path,
        predefinedAcl: 'publicRead',
        uploadOptions: api.UploadOptions(),
        uploadMedia: media,
      );
    }
  }

  Future<api.Object> _writeFileEmulator(
    BucketRest bucket,
    String path,
    Uint8List bytes,
    api.Object object,
    api.Media media,
  ) async {
    var initiateUri = Uri.parse(
      '$rootUrl'
      'upload/storage/v1/b/${Uri.encodeComponent(bucket.name)}/o',
    ).replace(queryParameters: {'uploadType': 'resumable', 'name': path});
    var initiateResponse = await authClient.post(
      initiateUri,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'x-upload-content-type': media.contentType,
        'x-upload-content-length': '${bytes.length}',
      },
      body: jsonEncode(object.toJson()),
    );
    var uploadUrl = initiateResponse.headers['location'];
    if (initiateResponse.statusCode != 200 || uploadUrl == null) {
      throw StateError(
        'Invalid response for resumable upload attempt '
        '(status was: ${initiateResponse.statusCode})',
      );
    }
    var uploadResponse = await authClient.put(
      Uri.parse(uploadUrl),
      headers: {'content-type': media.contentType},
      body: bytes,
    );
    if (uploadResponse.statusCode != 200 && uploadResponse.statusCode != 201) {
      throw StateError(
        'Resumable upload failed (status was: ${uploadResponse.statusCode})',
      );
    }
    return api.Object.fromJson(
      jsonDecode(uploadResponse.body) as Map<String, Object?>,
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
          object.name!,
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
  Reference ref([String? path]) {
    var uri = Uri.tryParse(path ?? '');
    if (uri == null || uri.scheme.isEmpty) {
      var fileRef = StorageFileRef(appRest.options.storageBucket!, path ?? '');
      return ReferenceRestImpl(storage: this, fileRef: fileRef);
    }

    var fileRef = StorageFileRef.fromLink(uri);
    return ReferenceRestImpl(storage: this, fileRef: fileRef);
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
