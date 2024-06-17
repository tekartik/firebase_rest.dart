// This is a modified version of a generated file (see the discoveryapis_generator project).
library tekartik_firebase_firestore.firestore_googleapis.firestore.v1beta1;

import 'v1.dart';

export 'v1.dart';

typedef FirestoreFixedApi = FirestoreApi;
typedef RunQueryFixedResponse = RunQueryResponse;
/*
// ignore_for_file: non_constant_identifier_names

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;
import 'dart:core' show override;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart' as http;

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;
export 'package:tekartik_firebase_firestore_rest/src/firestore/v1.dart';

/// Copied from user_agent.dart
/// Request headers used by all libraries in this package
final requestHeaders = {
  'user-agent': 'google-api-dart-client/2.0.0',
  'x-goog-api-client': 'gl-dart/${commons.dartVersion} gdcl/2.0.0',
};

/// Accesses the NoSQL document database built for automatic scaling, high
/// performance, and ease of application development.
class FirestoreFixedApi {
  final commons.ApiRequester _requester;

  ProjectsResourceFixedApi get projects => ProjectsResourceFixedApi(_requester);

  FirestoreFixedApi(http.Client client,
      {core.String rootUrl = 'https://firestore.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResourceFixedApi {
  final commons.ApiRequester _requester;

  ProjectsDatabasesResourceFixedApi get databases =>
      ProjectsDatabasesResourceFixedApi(_requester);

  ProjectsResourceFixedApi(commons.ApiRequester client) : _requester = client;
}

class ProjectsDatabasesResourceFixedApi {
  final commons.ApiRequester _requester;

  ProjectsDatabasesDocumentsResourceApi get documents =>
      ProjectsDatabasesDocumentsResourceApi(_requester);

  ProjectsDatabasesResourceFixedApi(commons.ApiRequester client)
      : _requester = client;
}

class ProjectsDatabasesDocumentsResourceApi {
  final commons.ApiRequester _requester;

  ProjectsDatabasesDocumentsResourceApi(commons.ApiRequester client)
      : _requester = client;

  /// Fixing...
  async.Future<RunQueryFixedResponse> runQuery(
      RunQueryRequest request, core.String parent,
      {core.String? $fields}) async {
    var _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };
    final _body = convert.json.encode(request.toJson());

    if ($fields != null) {
      _queryParams['fields'] = [$fields];
    }

    final _url = 'v1/' + core.Uri.encodeFull(parent) + ':runQuery';

    var _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );

    //core.print(_response);
    return RunQueryFixedResponse.fromJson(_response as core.List);
  }

  /// Updates or inserts a document.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the document, for example
  /// `projects/{project_id}/databases/{database_id}/documents/{document_path}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/databases/\[^/\]+/documents/\[^/\]+/.*$`.
  ///
  /// [currentDocument_exists] - When set to `true`, the target document must
  /// exist. When set to `false`, the target document must not exist.
  ///
  /// [currentDocument_updateTime] - When set, the target document must exist
  /// and have been last updated at that time.
  ///
  /// [mask_fieldPaths] - The list of field paths in the mask. See
  /// Document.fields for a field path syntax reference.
  ///
  /// [updateMask_fieldPaths] - The list of field paths in the mask. See
  /// Document.fields for a field path syntax reference.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Document].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Document> patch(
    Document request,
    core.String name, {
    core.bool? currentDocument_exists,
    core.String? currentDocument_updateTime,
    core.List<core.String>? mask_fieldPaths,
    core.List<core.String>? updateMask_fieldPaths,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (currentDocument_exists != null)
        'currentDocument.exists': ['$currentDocument_exists'],
      if (currentDocument_updateTime != null)
        'currentDocument.updateTime': [currentDocument_updateTime],
      if (mask_fieldPaths != null) 'mask.fieldPaths': mask_fieldPaths,
      if (updateMask_fieldPaths != null)
        'updateMask.fieldPaths': updateMask_fieldPaths,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull(name);

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return DocumentFixed.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a single document.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the Document to get. In the
  /// format:
  /// `projects/{project_id}/databases/{database_id}/documents/{document_path}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/databases/\[^/\]+/documents/\[^/\]+/.*$`.
  ///
  /// [mask_fieldPaths] - The list of field paths in the mask. See
  /// Document.fields for a field path syntax reference.
  ///
  /// [readTime] - Reads the version of the document at the given time. This may
  /// not be older than 270 seconds.
  ///
  /// [transaction] - Reads the document in a transaction.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Document].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Document> get(
    core.String name, {
    core.List<core.String>? mask_fieldPaths,
    core.String? readTime,
    core.String? transaction,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (mask_fieldPaths != null) 'mask.fieldPaths': mask_fieldPaths,
      if (readTime != null) 'readTime': [readTime],
      if (transaction != null) 'transaction': [transaction],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull(name);

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DocumentFixed.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// The response for Firestore.RunQuery.
class RunQueryFixedResponse {
  /// A query result.
  /// Not set when reporting partial progress.
  core.List<RunQueryFixedResponseDocument>? documents;

  RunQueryFixedResponse();

  RunQueryFixedResponse.fromJson(core.List _json) {
    core.print(_json);
    documents = _json
        .map((documentJson) =>
            RunQueryFixedResponseDocument.fromJson(documentJson as core.Map))
        .toList(growable: false);
  }

  core.List<core.Object> toJson() {
    return documents!
        .map((document) => document.toJson())
        .toList(growable: false);
  }
}

/// The response for Firestore.RunQuery.
class RunQueryFixedResponseDocument {
  /// A query result.
  ///
  /// Not set when reporting partial progress.
  Document? document;

  /// The time at which the document was read.
  ///
  /// This may be monotonically increasing; in this case, the previous documents
  /// in the result stream are guaranteed not to have changed between their
  /// `read_time` and this one. If the query returns no results, a response with
  /// `read_time` and no `document` will be sent, and this represents the time
  /// at which the query was run.
  core.String? readTime;

  /// The number of results that have been skipped due to an offset between the
  /// last response and the current response.
  core.int? skippedResults;

  /// The transaction that was started as part of this request.
  ///
  /// Can only be set in the first response, and only if
  /// RunQueryRequest.new_transaction was set in the request. If set, no other
  /// fields will be set in this response.
  core.String? transaction;

  core.List<core.int> get transactionAsBytes =>
      convert.base64.decode(transaction!);

  set transactionAsBytes(core.List<core.int> _bytes) {
    transaction =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  RunQueryFixedResponseDocument();

  RunQueryFixedResponseDocument.fromJson(core.Map _json) {
    if (_json.containsKey('document')) {
      document = DocumentFixed.fromJson(
          _json['document'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('readTime')) {
      readTime = _json['readTime'] as core.String;
    }
    if (_json.containsKey('skippedResults')) {
      skippedResults = _json['skippedResults'] as core.int;
    }
    if (_json.containsKey('transaction')) {
      transaction = _json['transaction'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (document != null) 'document': document!.toJson(),
        if (readTime != null) 'readTime': readTime!,
        if (skippedResults != null) 'skippedResults': skippedResults!,
        if (transaction != null) 'transaction': transaction!,
      };
}

/// A Firestore document.
///
/// Must not exceed 1 MiB - 4 bytes.
class DocumentFixed implements Document {
  /// The time at which the document was created.
  ///
  /// This value increases monotonically when a document is deleted then
  /// recreated. It can also be compared to values from other documents and the
  /// `read_time` of a query.
  ///
  /// Output only.
  @override
  core.String? createTime;

  /// The document's fields.
  ///
  /// The map keys represent field names. A simple field name contains only
  /// characters `a` to `z`, `A` to `Z`, `0` to `9`, or `_`, and must not start
  /// with `0` to `9`. For example, `foo_bar_17`. Field names matching the
  /// regular expression `__.*__` are reserved. Reserved field names are
  /// forbidden except in certain documented contexts. The map keys, represented
  /// as UTF-8, must not exceed 1,500 bytes and cannot be empty. Field paths may
  /// be used in other contexts to refer to structured fields defined here. For
  /// `map_value`, the field path is represented by the simple or quoted field
  /// names of the containing fields, delimited by `.`. For example, the
  /// structured field `"foo" : { map_value: { "x&y" : { string_value: "hello"
  /// }}}` would be represented by the field path `foo.x&y`. Within a field
  /// path, a quoted field name starts and ends with `` ` `` and may contain any
  /// character. Some characters, including `` ` ``, must be escaped using a
  /// `\`. For example, `` `x&y` `` represents `x&y` and `` `bak\`tik` ``
  /// represents `` bak`tik ``.
  @override
  core.Map<core.String, Value>? fields;

  /// The resource name of the document, for example
  /// `projects/{project_id}/databases/{database_id}/documents/{document_path}`.
  @override
  core.String? name;

  /// The time at which the document was last changed.
  ///
  /// This value is initially set to the `create_time` then increases
  /// monotonically with each change to the document. It can also be compared to
  /// values from other documents and the `read_time` of a query.
  ///
  /// Output only.
  @override
  core.String? updateTime;

  DocumentFixed();

  DocumentFixed.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('fields')) {
      fields = (_json['fields'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          ValueFixed.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  @override
  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (fields != null)
          'fields':
              fields!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (name != null) 'name': name!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// A message that can hold any of the supported value types.
class ValueFixed implements Value {
  /// An array value.
  ///
  /// Cannot directly contain another array value, though can contain an map
  /// which contains another array.
  @override
  @override
  ArrayValue? arrayValue;

  /// A boolean value.
  @override
  core.bool? booleanValue;

  /// A bytes value.
  ///
  /// Must not exceed 1 MiB - 89 bytes. Only the first 1,500 bytes are
  /// considered by queries.
  @override
  core.String? bytesValue;

  @override
  core.List<core.int> get bytesValueAsBytes =>
      convert.base64.decode(bytesValue!);

  @override
  set bytesValueAsBytes(core.List<core.int> _bytes) {
    bytesValue =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// A double value.
  @override
  core.double? doubleValue;

  /// A geo point value representing a point on the surface of Earth.
  @override
  LatLng? geoPointValue;

  /// An integer value.
  @override
  core.String? integerValue;

  /// A map value.
  @override
  MapValue? mapValue;

  /// A null value.
  /// Possible string values are:
  /// - "NULL_VALUE" : Null value.
  @override
  core.String? nullValue;

  /// A reference to a document.
  ///
  /// For example:
  /// `projects/{project_id}/databases/{database_id}/documents/{document_path}`.
  @override
  core.String? referenceValue;

  /// A string value.
  ///
  /// The string, represented as UTF-8, must not exceed 1 MiB - 89 bytes. Only
  /// the first 1,500 bytes of the UTF-8 representation are considered by
  /// queries.
  @override
  core.String? stringValue;

  /// A timestamp value.
  ///
  /// Precise only to microseconds. When stored, any additional precision is
  /// rounded down.
  @override
  core.String? timestampValue;

  ValueFixed();

  ValueFixed.fromJson(core.Map _json) {
    if (_json.containsKey('arrayValue')) {
      arrayValue = ArrayValue.fromJson(
          _json['arrayValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('booleanValue')) {
      booleanValue = _json['booleanValue'] as core.bool;
    }
    if (_json.containsKey('bytesValue')) {
      bytesValue = _json['bytesValue'] as core.String;
    }
    if (_json.containsKey('doubleValue')) {
      doubleValue = (_json['doubleValue'] as core.num).toDouble();
    }
    if (_json.containsKey('geoPointValue')) {
      geoPointValue = LatLng.fromJson(
          _json['geoPointValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('integerValue')) {
      integerValue = _json['integerValue'] as core.String;
    }
    if (_json.containsKey('mapValue')) {
      mapValue = MapValueFixed.fromJson(
          _json['mapValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nullValue')) {
      nullValue = _json['nullValue'] as core.String? ?? 'NULL_VALUE';
    }
    if (_json.containsKey('referenceValue')) {
      referenceValue = _json['referenceValue'] as core.String;
    }
    if (_json.containsKey('stringValue')) {
      stringValue = _json['stringValue'] as core.String;
    }
    if (_json.containsKey('timestampValue')) {
      timestampValue = _json['timestampValue'] as core.String;
    }
  }

  @override
  core.Map<core.String, core.dynamic> toJson() => {
        if (arrayValue != null) 'arrayValue': arrayValue!.toJson(),
        if (booleanValue != null) 'booleanValue': booleanValue!,
        if (bytesValue != null) 'bytesValue': bytesValue!,
        if (doubleValue != null) 'doubleValue': doubleValue!,
        if (geoPointValue != null) 'geoPointValue': geoPointValue!.toJson(),
        if (integerValue != null) 'integerValue': integerValue!,
        if (mapValue != null) 'mapValue': mapValue!.toJson(),
        if (nullValue != null) 'nullValue': nullValue!,
        if (referenceValue != null) 'referenceValue': referenceValue!,
        if (stringValue != null) 'stringValue': stringValue!,
        if (timestampValue != null) 'timestampValue': timestampValue!,
      };
}

/// A map value.
class MapValueFixed implements MapValue {
  /// The map's fields.
  ///
  /// The map keys represent field names. Field names matching the regular
  /// expression `__.*__` are reserved. Reserved field names are forbidden
  /// except in certain documented contexts. The map keys, represented as UTF-8,
  /// must not exceed 1,500 bytes and cannot be empty.
  @override
  core.Map<core.String, Value>? fields;

  MapValueFixed();

  MapValueFixed.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = (_json['fields'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          ValueFixed.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  @override
  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null)
          'fields':
              fields!.map((key, item) => core.MapEntry(key, item.toJson())),
      };
}
*/
