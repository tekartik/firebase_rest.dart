// {name: xxxxx.webp,
//bucket: xxxx.appspot.com,
//generation: 1587734906120630,
// metageneration: 1, contentType: image/webp,
//  timeCreated: 2020-04-24T13:28:26.120Z,
//  updated: 2020-04-24T13:28:26.120Z,
//  storageClass: STANDARD,
//  size: 2473806,
//   md5Hash: 0yezmHHeHRdq7iBlFYzHtw==,
//    contentEncoding: identity,
//    contentDisposition:
//     inline; filename*=utf-8''xxxxx.webp,
//      crc32c: Cz21LQ==, etag: CLbTzriVgekCEAE=,
//      downloadTokens: d47b6cf4-a2ac-4a7d-a058-2e1260599ab4}

class GsObjectInfo {
  final String? contentType;
  final int? size;
  final String? md5Hash;

  GsObjectInfo({required this.contentType, required this.size, this.md5Hash});

  @override
  int get hashCode => size ?? 0;

  @override
  bool operator ==(other) {
    if (other is GsObjectInfo) {
      if (other.size != size) {
        return false;
      }
      if (other.contentType != contentType) {
        return false;
      }
      if (other.md5Hash != md5Hash) {
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  String toString() {
    return {'size': size, 'contentType': contentType}.toString();
  }
}
