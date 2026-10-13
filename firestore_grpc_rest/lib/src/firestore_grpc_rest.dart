import 'dart:async';
import 'dart:convert';

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
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_rest/firebase_rest.dart'
    show firebaseRestClientAccessToken;

import 'firestore_grpc_rest_service.dart' show firestoreServiceGrpcRest;

/// Extension on [DocumentReference] to listen for updates using the Firestore gRPC Listen API.
extension DocumentReferenceGrpcRestExt on DocumentReference {
  /// Listen for updates to this document using the Firestore gRPC Listen API.
  ///
  /// One connection, authenticated with the token of the app client at the
  /// time of the listen ([grpcListenToken]): the stream ends with the
  /// connection (error or not). `onSnapshot` of [firestoreServiceGrpcRest]
  /// keeps it open across failures and auth changes.
  Stream<DocumentSnapshot> onGrpcSnapshot() {
    var ref = this;
    if (ref is! DocumentReferenceRestImpl) {
      throw UnsupportedError(
        'onGrpcSnapshot is only supported on REST-based DocumentReference (DocumentReferenceRestImpl).',
      );
    }
    return Stream.fromFuture(
      grpcListenToken(ref.firestoreRestImpl),
    ).asyncExpand((token) => grpcListenDocument(ref, token: token));
  }
}

/// The bearer token a listen of [firestoreRest] sends: `owner` on the
/// emulator as its owner, otherwise the one of the app client (a signed in
/// user id token, renewed when expiring or when [forceRefresh], a service
/// account access token), null when unauthenticated.
Future<String?> grpcListenToken(
  FirestoreRestImpl firestoreRest, {
  bool forceRefresh = false,
}) async {
  if (firestoreRest.emulatorOwner) {
    return 'owner';
  }
  return await firebaseRestClientAccessToken(
    firestoreRest.appImpl.client,
    forceRefresh: forceRefresh,
  );
}

/// One listen connection to the document [ref], authenticated with [token]
/// (none when null), opened on listen. The stream ends with the connection,
/// with its error if any.
Stream<DocumentSnapshot> grpcListenDocument(
  DocumentReferenceRestImpl ref, {
  required String? token,
}) {
  var firestoreRest = ref.firestoreRestImpl;
  var databaseName = firestoreRest.getDatabaseName();
  var documentName = firestoreRest.getDocumentName(ref.path);

  var baseUrl =
      firestoreRest.emulatorRootUrl ?? 'https://firestore.googleapis.com/';
  var uri = Uri.parse(baseUrl);
  var host = uri.host.isNotEmpty ? uri.host : 'firestore.googleapis.com';
  var port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
  var isSecure = uri.scheme == 'https';

  var metadata = <String, String>{
    'google-cloud-resource-prefix': databaseName,
    'x-goog-request-params': 'database=${Uri.encodeComponent(databaseName)}',
  };
  if (token != null) {
    metadata['authorization'] = 'Bearer $token';
  }

  var target = Target()
    ..documents = (Target_DocumentsTarget()..documents.add(documentName))
    ..targetId = 1;

  var listenRequest = ListenRequest()
    ..database = databaseName
    ..addTarget = target;

  ClientChannel? channel;
  StreamController<ListenRequest>? requestController;
  StreamSubscription<ListenResponse>? subscription;
  late StreamController<DocumentSnapshot> controller;

  void emit(api.Document doc) {
    controller.add(DocumentSnapshotRestImpl(firestoreRest, doc));
  }

  controller = StreamController<DocumentSnapshot>(
    onListen: () {
      try {
        channel = ClientChannel(
          host,
          port: port,
          options: ChannelOptions(
            credentials: isSecure
                ? const ChannelCredentials.secure()
                : const ChannelCredentials.insecure(),
          ),
        );
        requestController = StreamController<ListenRequest>()
          ..add(listenRequest);
        var responseStream = FirestoreClient(channel!).listen(
          requestController!.stream,
          options: CallOptions(metadata: metadata),
        );

        var hasBeenEmitted = false;
        subscription = responseStream.listen(
          (response) {
            try {
              if (response.hasDocumentChange()) {
                emit(_apiDocumentFromGrpc(response.documentChange.document));
                hasBeenEmitted = true;
              } else if (response.hasDocumentDelete()) {
                emit(api.Document(name: response.documentDelete.document));
                hasBeenEmitted = true;
              } else if (response.hasDocumentRemove()) {
                emit(api.Document(name: response.documentRemove.document));
                hasBeenEmitted = true;
              } else if (response.hasTargetChange()) {
                var targetChange = response.targetChange;
                if (targetChange.targetChangeType ==
                        TargetChange_TargetChangeType.CURRENT &&
                    !hasBeenEmitted) {
                  emit(api.Document(name: documentName));
                  hasBeenEmitted = true;
                }
              }
            } catch (e, st) {
              controller.addError(e, st);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
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
        controller.close();
      }
    },
    onCancel: () async {
      await subscription?.cancel();
      await requestController?.close();
      await channel?.shutdown();
    },
  );
  return controller.stream;
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
      restValue.timestampValue = _grpcTimestampToRest(grpcValue.timestampValue);
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

/// RFC 3339 text of a grpc timestamp, as in a rest document (nanoseconds
/// precision).
String _grpcTimestampToRest(grpc.Timestamp ts) =>
    Timestamp(ts.seconds.toInt(), ts.nanos).toIso8601String();

api.Document _apiDocumentFromGrpc(grpc.Document grpcDoc) {
  return api.Document()
    ..name = grpcDoc.name
    ..fields = grpcDoc.fields.map(
      (key, val) => MapEntry(key, _apiValueFromGrpc(val)),
    )
    ..createTime = grpcDoc.hasCreateTime()
        ? _grpcTimestampToRest(grpcDoc.createTime)
        : null
    ..updateTime = grpcDoc.hasUpdateTime()
        ? _grpcTimestampToRest(grpcDoc.updateTime)
        : null;
}
