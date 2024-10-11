import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase.dart';
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
class GsReference {
  String? bucket;
  String? name;

  void fromMap(Map map) {
    bucket = map['bucket'] as String?;
    name = map['name'] as String?;
  }

  Map<String, Object?> toDebugMap() => {'name': name};

  @override
  String toString() => toDebugMap().toString();
}

class GsReferenceListResponse {
  List<GsReference>? items;

  void fromMap(Map map) {
    var rawItems = map['items'];
    if (rawItems is List) {
      items = rawItems.map((e) => GsReference()..fromMap(e as Map)).toList();
    }
  }

  Map<String, Object?> toDebugMap() => {'items.length': items?.length};

  @override
  String toString() => toDebugMap().toString();
}

var _baseUrl = 'https://firebasestorage.googleapis.com/v0';

class UnauthenticatedStorageApi {
  //final App app;
  final AppOptions? appOptions;
  final Client? client;
  String? _storageBucket;

  String get storageBucket =>
      _storageBucket ??= appOptionsGetStorageBucket(appOptions!);

  String _getUrl(String bucket) => url.join(_baseUrl, 'b', bucket, 'o');

  /// The base url to use
  String _storageRoot(String? bucket) => _getUrl(bucket ?? storageBucket);

  // https://firebasestorage.googleapis.com/v0/b/xxxx.appspot.com";

  UnauthenticatedStorageApi(
      {String? storageBucket, this.appOptions, required this.client}) {
    _storageBucket = storageBucket;
  }

  // prefix: folder/
  Future<GsReferenceListResponse> list({String? bucket, String? prefix}) async {
    var uri = Uri.parse(_storageRoot(bucket));
    if (prefix != null) {
      uri = uri.replace(queryParameters: {'prefix': prefix});
    }
    var json = await httpClientRead(client!, httpMethodGet, uri);
    // devPrint(json);
    return GsReferenceListResponse()..fromMap(jsonDecode(json) as Map);
  }

  String getFileUrl(String name, {String? bucket}) {
    return url.join(_storageRoot(bucket), Uri.encodeComponent(name));
  }

  Future<GsObjectInfo> getInfo(GsReference ref) async {
    var text = await httpClientRead(
        client!, httpMethodGet, Uri.parse(getFileUrl(ref.name!)));
    var map = jsonDecode(text) as Map;
    // devPrint(map);
    return GsObjectInfo(
        contentType: map['contentType']?.toString(),
        size: parseInt(map['size']));
  }

  String getMediaUrl(String name, {String? bucket}) {
    return '${getFileUrl(name, bucket: bucket)}?alt=media';
  }
}
