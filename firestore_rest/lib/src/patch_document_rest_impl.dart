import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/value_key_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart'
    show FieldValueIncrement;
import 'package:tekartik_firebase_firestore_rest/src/document_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';

import 'firestore/v1.dart';

/// True if [value] is written as a server side transform (see
/// [WriteDocument.fieldTransforms]) rather than as a document field:
/// `FieldValue.increment` and `FieldValue.serverTimestamp`.
bool isFieldTransformValue(Object? value) =>
    value is FieldValueIncrement || value == FieldValue.serverTimestamp;

/// Set document.
class SetDocument extends WriteDocument {
  /// Constructor.
  SetDocument(super.firestore, super.data) : super(merge: false);
}

/// Set merged document.
class SetMergedDocument extends WriteDocument {
  /// Constructor.
  SetMergedDocument(super.firestore, super.data) : super(merge: false);

  @override
  void _fromMap(Map map) {
    _currentParent = null;
    // A merge always has an update mask, possibly empty (no field written,
    // the document being only created if missing, like the official SDKs).
    fieldPaths = [];
    _fields = _firstMapToFields(map);
  }

  /// Need escape?
  String _toKeyPath(List<String> keys) {
    return keys.map((key) => restEscapeKey(key)).join('.');
  }

  String _keyToString(String key) {
    // print('key: $key');
    return key.toString();
  }

  Map<String, Value> _firstMapToFields(Map map) {
    var fields = <String, Value>{};

    map.forEach((key, value) {
      var topStringKey = _keyToString(key.toString());

      /// keys will be added
      void handleMapGetKeys(List<String> keys, Map subMap) {
        subMap.forEach((key, value) {
          var stringKey = _keyToString(key.toString());

          var newKeys = [...keys, stringKey];
          if (value is Map && value.isNotEmpty) {
            handleMapGetKeys(newKeys, value);
          } else if (isFieldTransformValue(value)) {
            // Applied as a transform, not part of the update mask.
          } else {
            // A value, an empty map (set as is) or a delete.
            fieldPaths!.add(_toKeyPath(newKeys));
          }
        });
      }

      if (value is Map && value.isNotEmpty) {
        handleMapGetKeys([topStringKey], value);
      } else if (isFieldTransformValue(value)) {
        // Applied as a transform, not part of the update mask.
      } else {
        // A value, an empty map (set as is) or a delete.
        fieldPaths!.add(_toKeyPath([topStringKey]));
      }
      if (value == FieldValue.delete) {
        // Only in the update mask, not in the document.
      } else if (!_addFieldTransform(topStringKey, value)) {
        fields[topStringKey] = patchToRestValue(topStringKey, value);
      }
    });

    return fields;
  }
}

/// Update document.
class UpdateDocument extends WriteDocument {
  /// Constructor.
  UpdateDocument(super.firestore, super.data) : super(merge: true);

  @override
  void _fromMap(Map? map) {
    // An update always has an update mask, possibly empty (no field written
    // but the document must exist).
    fieldPaths = [];
    if (map == null) {
      return;
    }
    _currentParent = null;
    _fields = _firstMapToFields(map);
  }

  Map<String, Value> _firstMapToFields(Map map) {
    var fields = <String, Value>{};
    map.forEach((key, value) {
      final stringKey = key.toString();

      if (!isFieldTransformValue(value)) {
        // A dotted update key is a nested field path, escaped like the
        // transforms field paths.
        fieldPaths!.add(getFieldParts(stringKey).map(restEscapeKey).join('.'));
      }
    });

    var expanded = expandUpdateData(map)!;

    expanded.forEach((key, value) {
      final stringKey = key.toString();

      if (value == FieldValue.delete) {
        // Don't set it  in the fields but add
        // it to fieldPaths.
      } else if (_addFieldTransform(stringKey, value)) {
        // Applied as a transform, not part of the document.
      } else {
        // Build the tree

        // TODO test empty update
        fields[stringKey] = patchToRestValue(stringKey, value);
      }
    });
    return fields;
  }

  @override
  Map<String, Value> _mapToFields(String? me, Map map) {
    var fields = <String, Value>{};
    map.forEach((key, value) {
      final stringKey = key.toString();

      if (value == FieldValue.delete) {
        // Don't set it  in the fields but added in field paths
      } else if (_addFieldTransform(stringKey, value)) {
        // Applied as a transform, not part of the document.
      } else {
        fields[stringKey] = patchToRestValue(stringKey, value);
      }
    });
    return fields;
  }
}

/// Write document.
class WriteDocument with DocumentContext {
  /// firestore context.
  @override
  final FirestoreDocumentContext firestore;

  /// Merge option.
  bool merge;

  /// Native document.
  final document = Document();

  /// Computed initially in merged.
  List<String>? fieldPaths;

  /// The server side transforms (`FieldValue.increment`,
  /// `FieldValue.serverTimestamp`) to apply after the document update, in a
  /// commit request, `null` if none.
  ///
  /// A transformed field is neither part of the document [fields] nor of
  /// [fieldPaths] (the update mask), so that the transform is applied to the
  /// value currently stored.
  List<FieldTransform>? fieldTransforms;

  Map<String, Value>? _fields;

  /// The keys of the maps enclosing the map being converted (top-level key
  /// first), used to build the field path of a transform.
  final _parentKeys = <String>[];

  /// Constructor.
  WriteDocument(this.firestore, Map data, {required this.merge}) {
    _fromMap(data);
    document.fields = _fields;
  }

  /// Fields.
  Map<String, Value>? get fields => document.fields;

  void _fromMap(Map map) {
    _currentParent = null;
    _fields = _mapToFields(null, map);
  }

  String? _currentParent;

  /// If [value] is a transform value (see [isFieldTransformValue]), adds the
  /// transform of the field [key] of the map being converted to
  /// [fieldTransforms] and returns `true`; returns `false` otherwise.
  bool _addFieldTransform(String key, Object? value) {
    FieldTransform transform;
    if (value is FieldValueIncrement) {
      transform = FieldTransform()..increment = super.toRestValue(value.data);
    } else if (value == FieldValue.serverTimestamp) {
      // The time at which the server processed the request.
      transform = FieldTransform()..setToServerValue = 'REQUEST_TIME';
    } else {
      return false;
    }
    transform.fieldPath = [..._parentKeys, key].map(restEscapeKey).join('.');
    (fieldTransforms ??= []).add(transform);
    return true;
  }

  /// Patch to rest value.
  Value patchToRestValue(String key, dynamic value) {
    var me = _currentParent == null ? key : url.join(_currentParent!, key);

    if (value is Map) {
      _parentKeys.add(key);
      try {
        return _pathMapToRestValue(me, value);
      } finally {
        _parentKeys.removeLast();
      }
    }

    return super.toRestValue(value);
  }

  Map<String, Value> _mapToFields(String? me, Map map) {
    var fields = <String, Value>{};
    map.forEach((key, value) {
      final stringKey = key.toString();

      if (value == FieldValue.delete) {
        // Don't set it  in the fields but add
        // it to fieldPaths.
        if (merge) {
          fieldPaths ??= [];
          fieldPaths!.add(pathJoin(me, stringKey));
        }
      } else if (_addFieldTransform(stringKey, value)) {
        // Applied as a transform, not part of the document nor of the
        // update mask.
      } else {
        fields[stringKey] = patchToRestValue(stringKey, value);

        if (merge) {
          // add all field name
          fieldPaths ??= [];
          fieldPaths!.add(pathJoin(me, stringKey));
        }
      }
    });
    return fields;
  }

  Value _pathMapToRestValue(String me, Map value) {
    var oldCurrent = _currentParent;
    try {
      _currentParent = me;
      return _mapToRestValue(me, value);
    } finally {
      _currentParent = oldCurrent;
    }
  }

  Value _mapToRestValue(String me, Map map) {
    var mapValue = MapValue()..fields = _mapToFields(me, map);
    return Value()..mapValue = mapValue;
  }

  @override
  String toString() {
    return 'doc: $fieldsToString $fieldPaths${fieldTransforms != null ? ' transforms: $fieldTransformsToString' : ''}';
  }

  /// Fields to string.
  String get fieldsToString {
    var sb = StringBuffer();
    fields?.forEach((key, value) {
      if (sb.isNotEmpty) {
        sb.write(', ');
      }
      sb.write('$key: ${restValueToString(firestore, value)}');
    });
    if (sb.isEmpty && fields == null) {
      sb.write('(nullFields)');
    }
    return sb.toString();
  }

  /// Transforms to string.
  String get fieldTransformsToString {
    var sb = StringBuffer();
    fieldTransforms?.forEach((transform) {
      if (sb.isNotEmpty) {
        sb.write(', ');
      }
      var increment = transform.increment;
      var serverValue = transform.setToServerValue;
      if (increment != null) {
        sb.write(
          '${transform.fieldPath} += ${restValueToString(firestore, increment)}',
        );
      } else if (serverValue != null) {
        sb.write('${transform.fieldPath} = $serverValue');
      } else {
        sb.write('${transform.fieldPath}: ${transform.toJson()}');
      }
    });
    return sb.toString();
  }
}
