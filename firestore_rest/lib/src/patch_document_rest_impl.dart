import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/value_key_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_rest/src/document_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';

import 'firestore/v1_fixed.dart';

class SetDocument extends WriteDocument {
  SetDocument(super.firestore, super.data) : super(merge: false);
}

class SetMergedDocument extends WriteDocument {
  SetMergedDocument(super.firestore, super.data) : super(merge: false);

  @override
  void _fromMap(Map map) {
    _currentParent = null;
    _fields = _firstMapToFields(map);
  }

  /// Need escape?
  String _toKeyPath(List<String> keys) {
    return keys.map((key) => restEscapeKey(key)).join('.');
  }

  String _keyToString(String key) {
    print('key: $key');
    /*
    if (key.isNotEmpty && isDigit(key[0])) {
      return '`$key`';
    }*/

    return key.toString();
  }

  Map<String, Value> _firstMapToFields(Map map) {
    var fields = <String, Value>{};

    map.forEach((key, value) {
      var topStringKey = _keyToString(key.toString());

      /// keys will be added
      void handleMapGetKeys(List<String> keys, Map subMap) {
        fieldPaths ??= [];
        subMap.forEach((key, value) {
          var stringKey = _keyToString(key.toString());

          var newKeys = [...keys, stringKey];
          if (value is Map) {
            handleMapGetKeys(newKeys, value);
          } else {
            fieldPaths!.add(_toKeyPath(newKeys));
          }
        });
      }

      if (value is Map) {
        handleMapGetKeys([topStringKey], value);
      } else {
        fieldPaths ??= [];
        fieldPaths!.add(_toKeyPath([topStringKey]));
      }
      fields[topStringKey] = patchToRestValue(topStringKey, value);
    });

    return fields;
  }
}

class UpdateDocument extends WriteDocument {
  UpdateDocument(super.firestore, super.data) : super(merge: true);

  @override
  void _fromMap(Map? map) {
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

      fieldPaths ??= [];
      fieldPaths!.add(stringKey);
    });

    var expanded = expandUpdateData(map)!;

    expanded.forEach((key, value) {
      final stringKey = key.toString();

      if (value == FieldValue.delete) {
        // Don't set it  in the fields but add
        // it to fieldPaths.
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
      } else {
        fields[stringKey] = patchToRestValue(stringKey, value);
      }
    });
    return fields;
  }
}

class WriteDocument with DocumentContext {
  @override
  final FirestoreDocumentContext firestore;
  bool merge;
  final document = Document();

  /// Computed initially in merged.
  List<String>? fieldPaths;
  Map<String, Value>? _fields;

  WriteDocument(this.firestore, Map data, {required this.merge}) {
    _fromMap(data);
    document.fields = _fields;
  }

  Map<String, Value>? get fields => document.fields;

  void _fromMap(Map map) {
    _currentParent = null;
    _fields = _mapToFields(null, map);
  }

  String? _currentParent;

  Value patchToRestValue(String key, dynamic value) {
    var me = _currentParent == null ? key : url.join(_currentParent!, key);

    if (value is Map) {
      return _pathMapToRestValue(me, value);
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
    return 'doc: $fieldsToString $fieldPaths';
  }

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
}
