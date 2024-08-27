import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_firestore/utils/json_utils.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/collection_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/document_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/document_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/patch_document_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/query_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/transaction_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/write_batch.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_http/http.dart';

import 'aggregate_query_rest.dart';
import 'firestore/v1.dart' as api;
import 'firestore/v1.dart';
import 'import.dart';
import 'import_firestore.dart';

const restNullValue = 'NULL_VALUE';
const restRequestTime = 'REQUEST_TIME';

bool get debugRest => debugFirestoreRest; // devWarning(true); // false

/// Exported for strict debugging
var debugFirestoreRest = false; // devWarning(true);

bool _isDigit(String chr) => (chr.codeUnitAt(0) ^ 0x30) <= 9;

String restEscapeKey(String key) {
  if (key.isNotEmpty && _isDigit(key[0])) {
    return '`$key`';
  }
  return escapeKey(key);
}

dynamic dateOrTimestampValue(
    FirestoreDocumentContext firestore, String timestampValue) {
  var timestamp = Timestamp.tryParse(timestampValue);
  /*
  if (firestore?.impl?.firestoreSettings?.timestampsInSnapshots ?? true) {
    return timestamp;
  } else {
    return timestamp?.toDateTime();
  }
   */
  return timestamp;
}

Object? fromRestValue(FirestoreDocumentContext firestore, Value restValue) {
  if (restValue.nullValue == restNullValue) {
    return null;
  } else if (restValue.stringValue != null) {
    return restValue.stringValue;
  } else if (restValue.booleanValue != null) {
    return restValue.booleanValue;
  } else if (restValue.integerValue != null) {
    return int.tryParse(restValue.integerValue!);
  } else if (restValue.doubleValue != null) {
    return restValue.doubleValue;
  } else if (restValue.geoPointValue != null) {
    return GeoPoint(restValue.geoPointValue!.latitude!,
        restValue.geoPointValue!.longitude!);
  } else if (restValue.timestampValue != null) {
    return dateOrTimestampValue(firestore, restValue.timestampValue!);
  } else if (restValue.mapValue != null) {
    return mapFromMapValue(firestore, restValue.mapValue);
  } else if (restValue.arrayValue != null) {
    return _listFromArrayValue(firestore, restValue.arrayValue);
  } else if (restValue.bytesValue != null) {
    return Blob(Uint8List.fromList(restValue.bytesValueAsBytes));
  } else if (restValue.referenceValue != null) {
    return DocumentReferenceRestImpl(
        firestore.impl, firestore.getDocumentPath(restValue.referenceValue)!);
  } else {
    // This is null!
    if (isDebug) {
      print(
          '[firestore_rest] unsupported type ${restValue.runtimeType}: $restValue ${restValue.toJson()}');
      if (debugFirestoreRest) {
        throw UnsupportedError(
            '[firestore_rest] unsupported type ${restValue.runtimeType}: $restValue ${restValue.toJson()}');
      }
    }
    return null;
  }
}

String? restValueToString(FirestoreDocumentContext firestore, Value restValue) {
  if (restValue.nullValue == restNullValue) {
    return restValue.nullValue;
  } else if (restValue.stringValue != null) {
    return restValue.stringValue;
  } else if (restValue.booleanValue != null) {
    return restValue.booleanValue.toString();
  } else if (restValue.integerValue != null) {
    return restValue.integerValue;
  } else if (restValue.doubleValue != null) {
    return restValue.doubleValue.toString();
  } else if (restValue.geoPointValue != null) {
    return 'GeoPoint(${restValue.geoPointValue!.latitude}, ${restValue.geoPointValue!.longitude})';
  } else if (restValue.timestampValue != null) {
    return restValue.timestampValue;
  } else if (restValue.mapValue != null) {
    return mapFromMapValue(firestore, restValue.mapValue)?.toString();
  } else if (restValue.arrayValue != null) {
    return _listFromArrayValue(firestore, restValue.arrayValue).toString();
  } else if (restValue.bytesValue != null) {
    return Blob(Uint8List.fromList(restValue.bytesValueAsBytes)).toString();
  } else if (restValue.referenceValue != null) {
    return DocumentReferenceRestImpl(firestore.impl,
            firestore.getDocumentPath(restValue.referenceValue)!)
        .toString();
  } else {
    throw UnsupportedError('type ${restValue.runtimeType}: $restValue');
  }
}

Value _mapToRestValue(FirestoreRestImpl firestore, Map map) {
  var mapValue = MapValue()..fields = _mapToFields(firestore, map);
  return Value()..mapValue = mapValue;
}

Map<String, Value> _mapToFields(FirestoreRestImpl firestore, Map map) {
  var fields = map.map(
      (key, value) => MapEntry(key.toString(), toRestValue(firestore, value)));
  return fields;
}

Map<String, Object?>? mapFromMapValue(
    FirestoreDocumentContext firestore, MapValue? mapValue) {
  if (mapValue != null) {
    return mapFromFields(firestore, mapValue.fields) ?? <String, Object?>{};
  }
  return null;
}

Map<String, Object?>? mapFromFields(
    FirestoreDocumentContext firestore, Map<String, Value>? fields) {
  if (fields == null) {
    return null;
  }
  var map = fields.map((key, value) =>
      MapEntry(key.toString(), fromRestValue(firestore, value)));
  return map;
}

Value _listToRestValue(FirestoreRestImpl firestore, Iterable list) {
  var arrayValue = ArrayValue()..values = listToRestValues(firestore, list);
  return Value()..arrayValue = arrayValue;
}

List<Value> listToRestValues(FirestoreRestImpl firestore, Iterable list) {
  return list
      .map((value) => toRestValue(firestore, value))
      .toList(growable: false);
}

List<Object?> _listFromArrayValue(
    FirestoreDocumentContext firestore, ArrayValue? arrayValue) {
  var list = arrayValue?.values
      ?.map((restValue) => fromRestValue(firestore, restValue))
      .toList(growable: false);
  return list ?? <Object?>[];
}

Value toRestValue(FirestoreRestImpl firestore, dynamic value) {
  Value restValue;
  if (value == null) {
    restValue = Value()..nullValue = 'NULL_VALUE';
  } else if (value is String) {
    restValue = Value()..stringValue = value;
  } else if (value is bool) {
    restValue = Value()..booleanValue = value;
  } else if (value is int) {
    restValue = Value()..integerValue = value.toString();
  } else if (value is double) {
    restValue = Value()..doubleValue = value;
  } else if (value is GeoPoint) {
    var geoPointValue = LatLng()
      ..latitude = value.latitude.toDouble()
      ..longitude = value.longitude.toDouble();
    restValue = Value()..geoPointValue = geoPointValue;
  } else if (value is Timestamp) {
    restValue = Value()..timestampValue = value.toString();
  } else if (value is DateTime) {
    restValue = Value()
      ..timestampValue = Timestamp.fromDateTime(value).toIso8601String();
  } else if (value is Map) {
    restValue = _mapToRestValue(firestore, value);
  } else if (value is Iterable) {
    restValue = _listToRestValue(firestore, value);
  } else if (value is Blob) {
    restValue = Value()..bytesValueAsBytes = value.data;
  } else if (value is DocumentReference) {
    restValue = Value()..referenceValue = firestore.getDocumentName(value.path);
    // else  if (value is FieldValue) {
    //restValue = Value()..nullValue= 'NULL_VALUE';
  } else if (value is FieldValue) {
    if (value == FieldValue.serverTimestamp) {
      // TODO for now use local date time
      restValue = Value()..timestampValue = Timestamp.now().toIso8601String();
      //}
      //if (value == FieldValue.delete) {
      //  restValue = Value()..timestampValue = Timestamp.now().toIso8601String();
    } else {
      throw UnsupportedError('FieldValue ${value.runtimeType}: $value');
    }
  } else {
    throw UnsupportedError('type ${value.runtimeType}: $value');
  }
  return restValue;
}

class FirestoreRestImpl
    with
        FirebaseAppProductMixin<Firestore>,
        FirestoreDefaultMixin,
        FirestoreMixin
    implements Firestore, FirestoreDocumentContext {
  @override
  final FirestoreServiceRestImpl service;
  final FirebaseAppRest appImpl;
  api.FirestoreApi? _firestoreApi;

  http.Client? _lastApiClient;
  api.FirestoreApi get firestoreApi {
    if (_lastApiClient == appImpl.client) {
      return _firestoreApi!;
    } else {
      _lastApiClient = appImpl.client;
      return _firestoreApi = FirestoreApi(appImpl.client!);
    }
  }

  String? get projectId => appImpl.options.projectId;

  FirestoreRestImpl(this.service, this.appImpl) {
    assert(projectId != null);
  }

  @override
  WriteBatch batch() => WriteBatchRestImpl(this);

  @override
  CollectionReference collection(String path) {
    return CollectionReferenceRestImpl(this, path);
  }

  // join('projects/${projectId}/databases/(default)/documents', path);
  @override
  String getDocumentName(String? path) {
    return url.join(getDocumentRootName(), path);
  }

  String getDocumentRootName() {
    return url.join(getDatabaseName(), 'documents');
  }

  /// Remove
  @override
  String getDocumentPath(String? name) {
    var parts = url.split(name!);
    return url.joinAll(parts.sublist(5));
  }

  // 'projects/${projectId}/databases/(default)';
  String getDatabaseName() {
    return url.join('projects', projectId, 'databases', '(default)');
  }

  @override
  DocumentReference doc(String path) {
    return DocumentReferenceRestImpl(this, path);
  }

  Future<DocumentSnapshot> getDocument(String path,
      {String? transactionId}) async {
    var name = getDocumentName(path);
    try {
      // devPrint('name $name');
      if (debugRest) {
        print('documentGetRequest: $name, transactionId: $transactionId');
      }
      var document = await firestoreApi.projects.databases.documents
          .get(name, transaction: transactionId);
      // Debug read
      if (debugRest) {
        print('documentGet: ${jsonPretty(document.toJson())}');
      }
      return DocumentSnapshotRestImpl(this, document);
    } catch (e) {
      if (e is api.DetailedApiRequestError) {
        // devPrint(e.status);
        if (e.status == httpStatusCodeNotFound) {
          return DocumentSnapshotRestImpl(this, Document()..name = name);
        }
      }
      rethrow;
    }
  }

  Future deleteDocument(String path) async {
    if (debugRest) {
      print('delete $path');
    }
    var name = getDocumentName(path);
    try {
      await firestoreApi.projects.databases.documents.delete(name);
    } catch (e) {
      if (e is api.DetailedApiRequestError) {
        return;
      }
      rethrow;
    }
  }

  @override
  Future<T> runTransaction<T>(
      FutureOr<T> Function(Transaction transaction) updateFunction) async {
    var transaction = TransactionRestImpl(this);
    var transactionId = transaction.transactionId = await beginTransaction();
    T result;
    try {
      result = await updateFunction(transaction);
      await commitBatch(transaction);
    } catch (e) {
      await _rollback(transactionId);
      rethrow;
    }
    return result;
  }

  String get baseUri =>
      'https://firestore.googleapis.com/v1beta1/$projectId/tekartik-free-dev/databases/(default)';

  String getUriPath(String path) {
    return url.join(baseUri, path);
  }

  Future<DocumentReference> createDocument(
      String path, Map<String, Object?> data) async {
    var document = Document()..fields = _mapToFields(this, data);

    var parent = url.dirname(getDocumentName(path));
    var collectionId = getPathId(path);
    if (debugRest) {
      print(
          'createDocumentRequest: ${jsonPretty(document.toJson())}, parent: $parent, collectionId: $collectionId');
    }
    document = await firestoreApi.projects.databases.documents
        .createDocument(document, parent, collectionId);
    if (debugRest) {
      print('createDocument: ${jsonPretty(document.toJson())}');
    }
    return DocumentReferenceRestImpl(this, document.name!);
  }

  Future<DocumentReference> writeDocument(
      String path, Map<String, Object?> data,
      {required bool? merge, String? transactionId}) async {
    WriteDocument patch;
    if (merge ?? false) {
      patch = SetMergedDocument(this, data);
    } else {
      patch = SetDocument(this, data);
    }
    // var patchedDocument =
    var name = getDocumentName(path);
    // devPrint('patch $name: $data');
    if (debugRest) {
      print(
          'writeDocumentRequest: ${jsonPretty(patch.document.toJson())}, name: $name, updateFieldPaths: ${patch.fieldPaths}');
    }
    try {
      var document = await firestoreApi.projects.databases.documents
          .patch(patch.document, name, updateMask_fieldPaths: patch.fieldPaths);
      if (debugRest) {
        print('writeDocument: ${jsonPretty(document.toJson())}');
      }
    } catch (e) {
      if (debugRest) {
        print('writeDocument error: $e');
      }
      rethrow;
    }
    return DocumentReferenceRestImpl(this, path);
  }

  Future<DocumentReference> updateDocument(
      String path, Map<String, Object?> data) async {
    var patch = UpdateDocument(this, data);
    // var document = Document()..fields = _mapToFields(this, data);
    // document =
    var name = getDocumentName(path);
    // devPrint('update $name: $data');

    if (debugRest) {
      print(
          'updateDocumentRequest: ${jsonPretty(patch.document.toJson())}, name: $name, updateFieldPaths: ${patch.fieldPaths}');
    }
    try {
      var document = await firestoreApi.projects.databases.documents.patch(
          patch.document, name,
          currentDocument_exists: true,
          updateMask_fieldPaths: patch.fieldPaths);
      if (debugRest) {
        print('updateDocument: ${jsonPretty(document.toJson())}');
      }
    } catch (e) {
      if (debugRest) {
        print('updateDocument error: $e');
      }
      rethrow;
    }
    return DocumentReferenceRestImpl(this, path);
  }

  Filter whereToFilter(WhereInfo whereInfo) {
    if (whereInfo.isNull == true) {
      return Filter()
        ..unaryFilter = (UnaryFilter()
          ..field = (FieldReference()..fieldPath = whereInfo.fieldPath)
          ..op = 'IS_NULL');
    }
    // Operator
    //A field filter operator.
    //
    //Enums
    //OPERATOR_UNSPECIFIED	Unspecified. This value must not be used.
    //LESS_THAN	Less than. Requires that the field come first in orderBy.
    //LESS_THAN_OR_EQUAL	Less than or equal. Requires that the field come first in orderBy.
    //GREATER_THAN	Greater than. Requires that the field come first in orderBy.
    //GREATER_THAN_OR_EQUAL	Greater than or equal. Requires that the field come first in orderBy.
    //EQUAL	Equal.
    //ARRAY_CONTAINS	Contains. Requires that the field is an array.

    String? op;
    dynamic value;
    if (whereInfo.isEqualTo != null) {
      op = 'EQUAL';
      value = whereInfo.isEqualTo;
    } else if (whereInfo.isGreaterThan != null) {
      op = 'GREATER_THAN';
      value = whereInfo.isGreaterThan;
    } else if (whereInfo.isGreaterThanOrEqualTo != null) {
      op = 'GREATER_THAN_OR_EQUAL';
      value = whereInfo.isGreaterThanOrEqualTo;
    } else if (whereInfo.isLessThan != null) {
      op = 'LESS_THAN';
      value = whereInfo.isLessThan;
    } else if (whereInfo.isLessThanOrEqualTo != null) {
      op = 'LESS_THAN_OR_EQUAL';
      value = whereInfo.isLessThanOrEqualTo;
    } else if (whereInfo.arrayContains != null) {
      op = 'ARRAY_CONTAINS';
      value = whereInfo.arrayContains;
    } else if (whereInfo.arrayContainsAny != null) {
      op = 'ARRAY_CONTAINS_ANY';
      value = whereInfo.arrayContainsAny;
    } else if (whereInfo.whereIn != null) {
      op = 'IN';
      value = whereInfo.whereIn;
    }
    if (op != null && value != null) {
      return Filter()
        ..fieldFilter = (FieldFilter()
          ..field = (FieldReference()..fieldPath = whereInfo.fieldPath)
          ..op = op
          ..value = toRestValue(this, value));
    }
    throw UnsupportedError('where $whereInfo');
  }

  String indexAlias(int index) => 'field_$index';
  int aliasIndex(String alias) => int.parse(alias.substring('field_'.length));
  Aggregation toAggregation(int index, AggregateField aggregateField) {
    var alias = indexAlias(index);
    if (aggregateField is AggregateFieldCount) {
      return Aggregation(alias: alias, count: Count());
    } else if (aggregateField is AggregateFieldSum) {
      return Aggregation(
          alias: alias,
          sum: Sum()
            ..field = (FieldReference()..fieldPath = aggregateField.field));
    } else if (aggregateField is AggregateFieldAverage) {
      return Aggregation(
          alias: alias,
          avg: Avg()
            ..field = (FieldReference()..fieldPath = aggregateField.field));
    }
    throw ArgumentError(aggregateField);
  }

  StructuredAggregationQuery toStructuredAggregationQuery(
      AggregateQueryRest aggregateQueryRest) {
    var queryRest = aggregateQueryRest.queryRest;
    var structuredQuery = toStructuredQuery(queryRest);
    var structuredAggregationQuery = StructuredAggregationQuery()
      ..structuredQuery = structuredQuery;
    structuredAggregationQuery.aggregations = aggregateQueryRest.fields.indexed
        .map((e) => toAggregation(e.$1, e.$2))
        .toList(growable: false);
    return structuredAggregationQuery;
  }

  StructuredQuery toStructuredQuery(QueryRestImpl queryRestImpl) {
    var queryInfo = queryRestImpl.queryInfo;
    var collectionPath = queryRestImpl.path;
    var structuredQuery = StructuredQuery();

    // Support from
    structuredQuery.from = [
      CollectionSelector()..collectionId = getPathId(collectionPath)
    ];

    // Support select
    if (queryInfo.selectKeyPaths != null) {
      structuredQuery.select = Projection()
        ..fields = queryInfo.selectKeyPaths!
            .map((key) => FieldReference()..fieldPath = key)
            .toList(growable: false);
    }
    // Support where
    if (queryInfo.wheres.isNotEmpty) {
      if (queryInfo.wheres.length == 1) {
        structuredQuery.where = whereToFilter(queryInfo.wheres.first);
      } else {
        structuredQuery.where = Filter()
          ..compositeFilter = (CompositeFilter()
            ..op = 'AND'
            ..filters = queryInfo.wheres
                .map((whereInfo) => whereToFilter(whereInfo))
                .toList(growable: false));
      }
    }

    // Support limit and offset
    structuredQuery.limit = queryInfo.limit;
    structuredQuery.offset = queryInfo.offset;

    List<Value> toRestValues(List list) {
      var restValues = <Value>[];
      for (var i = 0; i < list.length; i++) {
        if (queryInfo.orderBys[i].fieldPath == firestoreNameFieldPath) {
          // Make it a document reference with an added '/'?????
          var id = list[i]?.toString();
          restValues.add(Value()
            ..referenceValue = getDocumentName(pathJoin(collectionPath, id)));
        } else {
          restValues.add(toRestValue(this, list[i]));
        }
      }
      return restValues;
    }

    // TODO support startAt
    if (queryInfo.startLimit != null) {
      // StartAt/StartAfter
      structuredQuery.startAt = Cursor()
        ..before = queryInfo.startLimit!.inclusive
        ..values = toRestValues(queryInfo.startLimit!.values!);
    }
    if (queryInfo.endLimit != null) {
      // StartAt/StartAfter
      structuredQuery.endAt = Cursor()
        ..before = !queryInfo.endLimit!.inclusive
        ..values = toRestValues(queryInfo.endLimit!.values!);
    }

    structuredQuery.orderBy = queryInfo.orderBys
        .map((info) => Order()
          ..field = (FieldReference()..fieldPath = info.fieldPath)
          ..direction = toRestDirection(info.ascending))
        .toList(growable: false);

    return structuredQuery;
  }

  String toRestDirection(bool? ascending) {
    /// 'DIRECTION_UNSPECIFIED';
    /// 'ASCENDING' : Ascending.
    /// 'DESCENDING'
    if (ascending == true) {
      return 'ASCENDING';
    } else if (ascending == null) {
      return 'DIRECTION_UNSPECIFIED';
    } else {
      return 'DESCENDING';
    }
  }

  Future<AggregateQuerySnapshotRest> runAggregationQuery(
      AggregateQueryRest aggregateQueryRest) async {
    var queryRest = aggregateQueryRest.queryRest;
    var request = RunAggregationQueryRequest()
      ..structuredAggregationQuery =
          toStructuredAggregationQuery(aggregateQueryRest);

    var parent = url.dirname(getDocumentName(queryRest.path));
    try {
      // Debug
      // devPrint('request: ${jsonPretty(request.toJson())}');
      // devPrint('parent: $parent');
      var response = await firestoreApi.projects.databases.documents
          .runAggregationQuery(request, parent);

      // devPrint(jsonPretty(response.map((e) => e.toJson()).toList()));
      // Example:
      // [
      //   {
      //     "readTime": "2024-01-30T23:30:18.619327Z",
      //     "result": {
      //       "aggregateFields": {
      //         "field_0": {
      //           "integerValue": "1"
      //         },
      //         "field_1": {
      //           "doubleValue": 2.0
      //         },
      //         "field_2": {
      //           "integerValue": "2"
      //         }
      //       }
      //     }
      //   }
      // ]
      // devPrint('get ${jsonPretty(response.toJson())}');
      return AggregateQuerySnapshotRest(aggregateQueryRest, response);
    } catch (e) {
      if (e is api.DetailedApiRequestError) {
        // devPrint(e.status);
        if (e.status == httpStatusCodeNotFound) {
          // return DocumentSnapshotRestImpl(this, null);
        }
      }
      rethrow;
    }
  }

  Future<QuerySnapshot> runQuery(QueryRestImpl queryRestImpl) async {
    var structuredQuery = toStructuredQuery(queryRestImpl);

    var request = RunQueryRequest()..structuredQuery = structuredQuery;

    var parent = url.dirname(getDocumentName(queryRestImpl.path));

    try {
      // Debug
      // devPrint('request: ${jsonPretty(request.toJson())}');
      // devPrint('parent: $parent');
      var response = await firestoreApi.projects.databases.documents
          .runQuery(request, parent);

      // devPrint(jsonPretty(response.toJson()));
      // devPrint('get ${jsonPretty(response.toJson())}');
      return QuerySnapshotRestImpl(this, response);
    } catch (e) {
      if (e is api.DetailedApiRequestError) {
        // devPrint(e.status);
        if (e.status == httpStatusCodeNotFound) {
          // return DocumentSnapshotRestImpl(this, null);
        }
      }
      rethrow;
    }
  }

  @override
  FirestoreRestImpl get impl => this;

  Future<String?> beginTransaction({bool? readOnly}) async {
    readOnly ??= false;
    var beginTransactionRequest = BeginTransactionRequest()
      ..options = (TransactionOptions()
        ..readWrite = readOnly ? null : ReadWrite()
        ..readOnly = readOnly ? ReadOnly() : null);
    var database = getDatabaseName();
    BeginTransactionResponse beginTransactionResponse;
    try {
      // Debug
      if (debugRest) {
        print(
            'beginTransactionRequest: ${jsonPretty(beginTransactionRequest.toJson())}');
      }
      beginTransactionResponse = await firestoreApi.projects.databases.documents
          .beginTransaction(beginTransactionRequest, database);

      // devPrint(jsonPretty(response.toJson()));
      if (debugRest) {
        print(
            'beginTransaction ${jsonPretty(beginTransactionResponse.toJson())}');
      }
      return beginTransactionResponse.transaction;
    } catch (e) {
      // devPrint(e);
      if (e is api.DetailedApiRequestError) {
        // devPrint(e.status);
        if (e.status == httpStatusCodeNotFound) {
          // return DocumentSnapshotRestImpl(this, null);
        }
      }
      rethrow;
    }
  }

  Future _rollback(String? transactionId) async {
    var database = getDatabaseName();
    try {
      var rollbackRequest = RollbackRequest()..transaction = transactionId;
      // Debug
      // devPrint('rollbackRequest: ${jsonPretty(rollbackRequest.toJson())}');

      // ignore: unused_local_variable
      var response = await firestoreApi.projects.databases.documents
          .rollback(rollbackRequest, database);

      // devPrint('rollback ${jsonPretty(response.toJson())}');
    } catch (rollbackError) {
      // devPrint(e);
      if (rollbackError is api.DetailedApiRequestError) {
        // devPrint(e.status);
        if (rollbackError.status == httpStatusCodeNotFound) {
          // return DocumentSnapshotRestImpl(this, null);
        }
      }
    }
  }

  Future _commitTransaction(String? transactionId) async {
    var request = CommitRequest()..transaction = transactionId;
    var database = getDatabaseName();
    try {
      // Debug
      if (debugRest) {
        print('commitRequest: ${jsonPretty(request.toJson())}');
      }
      // devPrint('commitRequest: ${jsonPretty(request.toJson())}');

      // ignore: unused_local_variable
      var response = await firestoreApi.projects.databases.documents
          .commit(request, database);

      // devPrint(jsonPretty(response.toJson()));
      if (debugRest) {
        print('commit ${jsonPretty(response.toJson())}');
      }
    } catch (e) {
      // devPrint(e);
      if (e is api.DetailedApiRequestError) {
        // devPrint(e.status);
        if (e.status == httpStatusCodeNotFound) {
          // return DocumentSnapshotRestImpl(this, null);
        }
      }
      rethrow;
    }
  }

  Future commitBatch(WriteBatchRestImpl writeBatchRestImpl) async {
    // begin it needed
    var transactionId =
        writeBatchRestImpl.transactionId ??= await beginTransaction();
    try {
      for (var operation in writeBatchRestImpl.operations) {
        // Somehow we need unawait here as write operation are blocked until
        // commit is callback. Still puzzled about operation that could fail
        // later...
        if (operation is WriteBatchOperationDelete) {
          deleteDocument(operation.docRef!.path).unawait();
        } else if (operation is WriteBatchOperationSet) {
          final setOperation = operation;
          writeDocument(
                  setOperation.docRef!.path, setOperation.documentData.asMap(),
                  merge: setOperation.options?.merge)
              .unawait();
        } else if (operation is WriteBatchOperationUpdate) {
          updateDocument(operation.docRef!.path, operation.documentData.asMap())
              .unawait();
        } else {
          throw UnsupportedError('operation $operation not supported');
        }
      }

      try {
        await _commitTransaction(transactionId);
      } catch (e) {
        // devPrint(e);
        if (e is api.DetailedApiRequestError) {
          // devPrint(e.status);
          if (e.status == httpStatusCodeNotFound) {
            // return DocumentSnapshotRestImpl(this, null);
          }
        }
        rethrow;
      }
    } catch (e) {
      try {
        await _rollback(transactionId);
      } catch (rollbackError) {
        // devPrint(e);
        if (e is api.DetailedApiRequestError) {
          // devPrint(e.status);
          if (e.status == httpStatusCodeNotFound) {
            // return DocumentSnapshotRestImpl(this, null);
          }
        }
      }

      // devPrint(e);
      rethrow;
    }
  }

  Future<List<CollectionReference>> _listCollections(String? path) async {
    var request = api.ListCollectionIdsRequest();
    var collections = <CollectionReference>[];
    try {
      while (true) {
        // Debug
        if (debugRest) {
          print('listCollections: ${jsonPretty(request.toJson())}');
        }
        // devPrint('commitRequest: ${jsonPretty(request.toJson())}');

        var parent =
            path != null ? getDocumentName(path) : getDocumentRootName();
        // ignore: unused_local_variable
        var response = await firestoreApi.projects.databases.documents
            .listCollectionIds(request, parent);
        print('response: ${jsonPretty(response.toJson())}');
        var stepCollections = (response.collectionIds ?? <String>[])
            .map((e) => collection(path == null ? e : url.join(path, e)))
            .toList();
        if (stepCollections.isEmpty) {
          break;
        }
        collections.addAll(stepCollections);
        if (response.nextPageToken == null) {
          break;
        }
        request.pageToken = response.nextPageToken;
      }
    } catch (e) {
      if (e is api.DetailedApiRequestError) {
        // devPrint(e.status);
        if (e.status == httpStatusCodeNotFound) {
          // return DocumentSnapshotRestImpl(this, null);
        }
      }
      rethrow;
    }
    return collections;
  }

  @override
  Future<List<CollectionReference>> listCollections() async {
    return await _listCollections(null);
  }

  Future<List<CollectionReference>> listDocumentCollections(String path) async {
    return _listCollections(path);
  }
}

class FirestoreServiceRestImpl
    with FirebaseProductServiceMixin<Firestore>, FirestoreServiceDefaultMixin
    implements FirestoreServiceRest {
  @override
  Firestore firestore(App app) {
    return getInstance(
        app, () => FirestoreRestImpl(this, app as FirebaseAppRest));
  }

  @override
  bool get supportsDocumentSnapshotTime => true;

  @override
  // TODO @alex implements?
  bool get supportsFieldValueArray => false;

  @override
  bool get supportsQuerySelect => true;

  @override
  bool get supportsQuerySnapshotCursor => false;

  @override
  bool get supportsTimestamps => true;

  @override
  bool get supportsTimestampsInSnapshots => true;

  @override
  bool get supportsTrackChanges => false;

  @override
  bool get supportsListCollections => true;

  @override
  bool get supportsAggregateQueries => true;
}

/// Join ignoring null but not both!
String pathJoin(String? path1, String? path2) {
  if (path1 == null) {
    return path2!;
  } else if (path2 == null) {
    return path1;
  } else {
    return url.join(path1, path2);
  }
}
