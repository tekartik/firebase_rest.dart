import 'dart:async';
import 'dart:convert';

import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as grpc;
import 'package:tekartik_firebase_firestore_grpc_rest/src/generated/google/firestore/v1/document.pb.dart'
    as grpc;
import 'package:tekartik_firebase_firestore_grpc_rest/src/generated/google/firestore/v1/firestore.pbgrpc.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/document_reference_rest.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1.dart'
    as api; // ignore: implementation_imports, unused_import
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart'; // ignore: implementation_imports, unused_import

/// Extension on [DocumentReference] to listen for updates using the Firestore gRPC Listen API.
extension DocumentReferenceGrpcRestExt on DocumentReference {
  /// Listen for updates to this document using the Firestore gRPC Listen API.
  Stream<DocumentSnapshot> onGrpcSnapshot() {
    var ref = this;
    if (ref is! DocumentReferenceRestImpl) {
      throw UnsupportedError(
        'onGrpcSnapshot is only supported on REST-based DocumentReference (DocumentReferenceRestImpl).',
      );
    }

    var firestoreRest = ref.firestoreRestImpl;
    var databaseName = firestoreRest.getDatabaseName();
    var documentName = firestoreRest.getDocumentName(ref.path);

    var baseUrl =
        firestoreRest.emulatorRootUrl ?? 'https://firestore.googleapis.com/';
    var uri = Uri.parse(baseUrl);
    var host = uri.host.isNotEmpty ? uri.host : 'firestore.googleapis.com';
    var port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
    var isSecure = uri.scheme == 'https';

    String? token;
    var appClient = firestoreRest.appImpl.client;
    if (appClient is AutoRefreshingAuthClient) {
      token = appClient.credentials.accessToken.data;
    }

    var metadata = <String, String>{
      'google-cloud-resource-prefix': databaseName,
      'x-goog-request-params': 'database=${Uri.encodeComponent(databaseName)}',
    };
    if (token != null) {
      metadata['authorization'] = 'Bearer $token';
    }

    var channel = ClientChannel(
      host,
      port: port,
      options: ChannelOptions(
        credentials: isSecure
            ? const ChannelCredentials.secure()
            : const ChannelCredentials.insecure(),
      ),
    );

    var grpcClient = FirestoreClient(channel);

    var target = Target()
      ..documents = (Target_DocumentsTarget()..documents.add(documentName))
      ..targetId = 1;

    var listenRequest = ListenRequest()
      ..database = databaseName
      ..addTarget = target;

    late StreamSubscription<ListenResponse> subscription;
    var requestController = StreamController<ListenRequest>();
    var controller = StreamController<DocumentSnapshot>(
      onCancel: () async {
        await subscription.cancel();
        await requestController.close();
        await channel.shutdown();
      },
    );

    // Run async setup
    unawaited(() async {
      try {
        requestController.add(listenRequest);

        var responseStream = grpcClient.listen(
          requestController.stream,
          options: CallOptions(metadata: metadata),
        );

        var hasBeenEmitted = false;

        subscription = responseStream.listen(
          (response) {
            try {
              if (response.hasDocumentChange()) {
                var change = response.documentChange;
                var doc = _apiDocumentFromGrpc(change.document);
                var snapshot = DocumentSnapshotRestImpl(firestoreRest, doc);
                controller.add(snapshot);
                hasBeenEmitted = true;
              } else if (response.hasDocumentDelete()) {
                var change = response.documentDelete;
                var name = change.document;
                var doc = api.Document(name: name);
                var snapshot = DocumentSnapshotRestImpl(firestoreRest, doc);
                controller.add(snapshot);
                hasBeenEmitted = true;
              } else if (response.hasDocumentRemove()) {
                var change = response.documentRemove;
                var name = change.document;
                var doc = api.Document(name: name);
                var snapshot = DocumentSnapshotRestImpl(firestoreRest, doc);
                controller.add(snapshot);
                hasBeenEmitted = true;
              } else if (response.hasTargetChange()) {
                var targetChange = response.targetChange;
                if (targetChange.targetChangeType ==
                    TargetChange_TargetChangeType.CURRENT) {
                  if (!hasBeenEmitted) {
                    var doc = api.Document(name: documentName);
                    var snapshot = DocumentSnapshotRestImpl(firestoreRest, doc);
                    controller.add(snapshot);
                    hasBeenEmitted = true;
                  }
                }
              }
            } catch (e, st) {
              controller.addError(e, st);
            }
          },
          onError: (Object error, StackTrace? stackTrace) {
            controller.addError(error, stackTrace);
            controller.close();
          },
          onDone: () {
            controller.close();
          },
          cancelOnError: true,
        );
      } catch (e, st) {
        controller.addError(e, st);
        await controller.close();
      }
    }());

    return controller.stream;
  }
}

api.Value _apiValueFromGrpc(grpc.Value grpcValue) {
  var restValue = api.Value();
  switch (grpcValue.whichValueType()) {
    case grpc.Value_ValueType.nullValue:
      restValue.nullValue = 'NULL_VALUE';
      break;
    case grpc.Value_ValueType.booleanValue:
      restValue.booleanValue = grpcValue.booleanValue;
      break;
    case grpc.Value_ValueType.integerValue:
      restValue.integerValue = grpcValue.integerValue.toString();
      break;
    case grpc.Value_ValueType.doubleValue:
      restValue.doubleValue = grpcValue.doubleValue;
      break;
    case grpc.Value_ValueType.timestampValue:
      var seconds = grpcValue.timestampValue.seconds.toInt();
      var nanos = grpcValue.timestampValue.nanos;
      var dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
      if (nanos > 0) {
        restValue.timestampValue = dt.toIso8601String().replaceFirst(
          'Z',
          '.${nanos.toString().padLeft(9, '0')}Z',
        );
      } else {
        restValue.timestampValue = dt.toIso8601String();
      }
      break;
    case grpc.Value_ValueType.stringValue:
      restValue.stringValue = grpcValue.stringValue;
      break;
    case grpc.Value_ValueType.bytesValue:
      restValue.bytesValue = base64.encode(grpcValue.bytesValue);
      break;
    case grpc.Value_ValueType.referenceValue:
      restValue.referenceValue = grpcValue.referenceValue;
      break;
    case grpc.Value_ValueType.geoPointValue:
      restValue.geoPointValue = api.LatLng()
        ..latitude = grpcValue.geoPointValue.latitude
        ..longitude = grpcValue.geoPointValue.longitude;
      break;
    case grpc.Value_ValueType.arrayValue:
      restValue.arrayValue = api.ArrayValue()
        ..values = grpcValue.arrayValue.values.map(_apiValueFromGrpc).toList();
      break;
    case grpc.Value_ValueType.mapValue:
      restValue.mapValue = api.MapValue()
        ..fields = grpcValue.mapValue.fields.map(
          (key, val) => MapEntry(key, _apiValueFromGrpc(val)),
        );
      break;
    case grpc.Value_ValueType.notSet:
      break;
  }
  return restValue;
}

api.Document _apiDocumentFromGrpc(grpc.Document grpcDoc) {
  String? formatTimestamp(grpc.Timestamp ts) {
    var seconds = ts.seconds.toInt();
    var nanos = ts.nanos;
    var dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    if (nanos > 0) {
      return dt.toIso8601String().replaceFirst(
        'Z',
        '.${nanos.toString().padLeft(9, '0')}Z',
      );
    }
    return dt.toIso8601String();
  }

  return api.Document()
    ..name = grpcDoc.name
    ..fields = grpcDoc.fields.map(
      (key, val) => MapEntry(key, _apiValueFromGrpc(val)),
    )
    ..createTime = grpcDoc.hasCreateTime()
        ? formatTimestamp(grpcDoc.createTime)
        : null
    ..updateTime = grpcDoc.hasUpdateTime()
        ? formatTimestamp(grpcDoc.updateTime)
        : null;
}
