import 'dart:convert';

import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart'; // ignore: implementation_imports

String _basePath(App app) {
  return 'projects/${app.options.projectId}/databases/(default)/documents';
}

Map<String, Object?> documentDataToJson(
  App app,
  DocumentData data, {
  Map<String, Object?>? map,
}) {
  map ??= <String, Object?>{};
  map['fields'] = (data as DocumentDataMap).map.map<String, Object?>(
    (key, value) => MapEntry(key, documentDataValueToJson(app, value)),
  );
  return map;
}

Map<String, Object?>? snapshotToJson(App app, DocumentSnapshot snapshot) {
  if (!snapshot.exists) {
    return null;
  }
  var map = <String, Object?>{
    'name': url.join(_basePath(app), snapshot.ref.path),
  };
  map = documentDataToJson(app, DocumentData(snapshot.data), map: map);
  map['createTime'] = snapshot.createTime?.toIso8601String();
  map['updateTime'] = snapshot.updateTime?.toIso8601String();
  return map;
}

DocumentData? documentDataFromSnapshot(DocumentSnapshot snapshot) =>
    snapshot.exists ? DocumentData(snapshot.data) : null;

dynamic documentDataValueToJson(App app, dynamic value) {
  if (value is String) {
    return <String, Object?>{'stringValue': value};
  } else if (value is int) {
    return <String, Object?>{'integerValue': value.toString()};
  } else if (value is num) {
    return <String, Object?>{'doubleValue': value};
  } else if (value is bool) {
    return <String, Object?>{'booleanValue': value};
  } else if (value is List) {
    return <String, Object?>{
      'arrayValue': {
        'values': value
            .map((value) => documentDataValueToJson(app, value))
            .toList(),
      },
    };
  } else if (value is Map) {
    return <String, Object?>{
      'mapValue': {
        'fields': value.map<String, Object?>(
          (key, value) =>
              MapEntry(key as String, documentDataValueToJson(app, value)),
        ),
      },
    };
  } else if (value is DocumentData) {
    // Handle this that could happen from a map
    return documentDataValueToJson(app, (value as DocumentDataMap).map);
  } else if (value is DateTime) {
    return <String, Object?>{'timestampValue': value.toUtc().toIso8601String()};
  } else if (value is Timestamp) {
    return <String, Object?>{'timestampValue': value.toIso8601String()};
  } else if (value is DocumentReference) {
    return <String, Object?>{
      'referenceValue': url.join(_basePath(app), value.path),
    };
  } else if (value is Blob) {
    return <String, Object?>{'bytesValue': base64.encode(value.data)};
  } else if (value is GeoPoint) {
    return <String, Object?>{
      'geoPointValue': {
        'latitude': value.latitude,
        'longitude': value.longitude,
      },
    };
  } else {
    throw ArgumentError.value(
      value,
      '${value.runtimeType}',
      'Unsupported value for documentDataValueToJson',
    );
  }
}
