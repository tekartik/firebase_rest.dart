import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_storage/utils/link.dart';
import 'package:tekartik_firebase_storage_rest/src/storage_json_impl.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_http/http_client.dart';

import 'src/import.dart';

export 'package:tekartik_firebase_storage/storage.dart';

// {
//  "prefixes": [],
//  "items": [
//    {
//      "name": "path/name",
//      "bucket": "bucket"
//    },
/// A single item entry as returned by the Firebase Storage json list REST
/// endpoint.
class GsReference {
  /// The bucket name.
  String? bucket;

  /// The object name (path).
  String? name;

  /// Populates this reference from a decoded json map.
  void fromMap(Map map) {
    bucket = map['bucket'] as String?;
    name = map['name'] as String?;
  }

  /// Debug map representation.
  Map<String, Object?> toDebugMap() => {'name': name};

  @override
  String toString() => toDebugMap().toString();
}

/// The response of the Firebase Storage json list REST endpoint.
class GsReferenceListResponse {
  /// The listed items.
  List<GsReference>? items;

  /// Populates this response from a decoded json map.
  void fromMap(Map map) {
    var rawItems = map['items'];
    if (rawItems is List) {
      items = rawItems.map((e) => GsReference()..fromMap(e as Map)).toList();
    }
  }

  /// Debug map representation.
  Map<String, Object?> toDebugMap() => {'items.length': items?.length};

  @override
  String toString() => toDebugMap().toString();
}

var _baseUrl = 'https://firebasestorage.googleapis.com/v0';

/// A minimal, unauthenticated client for the Firebase Storage json REST
/// endpoint (used to build public download urls).
class UnauthenticatedStorageApi {
  //final App app;
  /// The app options, used to resolve the default storage bucket.
  final AppOptions? appOptions;

  /// The http client to use.
  final Client? client;
  String? _storageBucket;

  /// The storage bucket to use.
  String get storageBucket =>
      _storageBucket ??= appOptionsGetStorageBucket(appOptions!);

  String _getUrl(String bucket) => url.join(_baseUrl, 'b', bucket, 'o');

  /// The base url to use
  String _storageRoot(String? bucket) => _getUrl(bucket ?? storageBucket);

  // https://firebasestorage.googleapis.com/v0/b/xxxx.appspot.com";

  /// A minimal, unauthenticated client for the Firebase Storage json REST
  /// endpoint.
  UnauthenticatedStorageApi({
    // compat
    String? storageBucket,
    this.appOptions,
    required this.client,
  }) {
    _storageBucket = storageBucket ?? appOptions?.storageBucket;
  }

  // prefix: folder/
  /// Lists the references under [prefix] in [bucket].
  Future<GsReferenceListResponse> list({String? bucket, String? prefix}) async {
    var uri = Uri.parse(_storageRoot(bucket));
    if (prefix != null) {
      uri = uri.replace(queryParameters: {'prefix': prefix});
    }
    var json = await httpClientRead(client!, httpMethodGet, uri);
    // devPrint(json);
    return GsReferenceListResponse()..fromMap(jsonDecode(json) as Map);
  }

  /// Builds the json REST url for the file named [name].
  String getFileUrl(String name, {String? bucket}) {
    return url.join(_storageRoot(bucket), Uri.encodeComponent(name));
  }

  /// Fetches the object info (content type, size) for [ref].
  Future<GsObjectInfo> getInfo(GsReference ref) async {
    var text = await httpClientRead(
      client!,
      httpMethodGet,
      Uri.parse(getFileUrl(ref.name!)),
    );
    var map = jsonDecode(text) as Map;
    // devPrint(map);
    return GsObjectInfo(
      contentType: map['contentType']?.toString(),
      size: parseInt(map['size']),
    );
  }

  /// Builds the public download url for [fileRef].
  String getDownloadUrl(StorageFileRef fileRef) {
    return getMediaUrl(fileRef.path, bucket: fileRef.bucket);
  }

  /// Builds the media (download) url for the file named [name].
  String getMediaUrl(String name, {String? bucket}) {
    return '${getFileUrl(name, bucket: bucket)}?alt=media';
  }
}
