import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/protobuf.dart'; // ignore: unused_import
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as grpc;
import 'package:tekartik_firebase_firestore_grpc_rest/firestore_grpc_rest.dart';
import 'package:tekartik_firebase_firestore_grpc_rest/src/generated/google/firestore/v1/document.pb.dart'
    as grpc;
import 'package:tekartik_firebase_firestore_grpc_rest/src/generated/google/firestore/v1/firestore.pbgrpc.dart'
    as grpc;
import 'package:tekartik_firebase_firestore_grpc_rest/src/generated/google/firestore/v1/write.pb.dart'
    as grpc;
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

class MockFirestoreService extends Service {
  @override
  String get $name => 'google.firestore.v1.Firestore';

  final StreamController<grpc.ListenResponse> responseController;

  MockFirestoreService(this.responseController) {
    $addMethod(
      ServiceMethod<grpc.ListenRequest, grpc.ListenResponse>(
        'Listen',
        listen,
        true,
        true,
        (List<int> value) => grpc.ListenRequest.fromBuffer(value),
        (grpc.ListenResponse value) => value.writeToBuffer(),
      ),
    );
  }

  Stream<grpc.ListenResponse> listen(
    ServiceCall call,
    Stream<grpc.ListenRequest> request,
  ) {
    return responseController.stream;
  }
}

void main() {
  group('onGrpcSnapshot', () {
    late Server server;
    late StreamController<grpc.ListenResponse> mockResponseController;
    late FirebaseApp app;
    late Firestore firestore;

    setUp(() async {
      mockResponseController = StreamController<grpc.ListenResponse>();
      server = Server.create(
        services: [MockFirestoreService(mockResponseController)],
      );
      await server.serve(address: 'localhost', port: 0);

      app = firebaseRest.initializeApp(
        options: AppOptionsRest()..projectId = 'test-project',
      );
      firestore = firestoreServiceRest.firestore(app);
      await (firestore as FirestoreRestImpl).useFirestoreEmulator(
        'localhost',
        server.port!,
      );
    });

    tearDown(() async {
      await app.delete();
      await server.shutdown();
      await mockResponseController.close();
    });

    test('emits document snapshots on documentChange', () async {
      var docRef = firestore.doc('test/doc');
      var completer = Completer<DocumentSnapshot>();
      var subscription = docRef.onGrpcSnapshot().listen((snap) {
        if (!completer.isCompleted) {
          completer.complete(snap);
        }
      });

      // Send initial documentChange via gRPC mock service
      var docProto = grpc.Document()
        ..name = 'projects/test-project/databases/(default)/documents/test/doc'
        ..fields['foo'] = (grpc.Value()..stringValue = 'bar')
        ..createTime = (grpc.Timestamp()..seconds = Int64(123456789))
        ..updateTime = (grpc.Timestamp()..seconds = Int64(123456789));

      var changeProto = grpc.DocumentChange()
        ..document = docProto
        ..targetIds.add(1);

      mockResponseController.add(
        grpc.ListenResponse()..documentChange = changeProto,
      );

      var snapshot = await completer.future.timeout(const Duration(seconds: 2));
      expect(snapshot.exists, isTrue);
      expect(snapshot.data, {'foo': 'bar'});

      await subscription.cancel();
    });

    test(
      'emits non-existing document snapshot on CURRENT when not yet emitted',
      () async {
        var docRef = firestore.doc('test/doc');
        var completer = Completer<DocumentSnapshot>();
        var subscription = docRef.onGrpcSnapshot().listen((snap) {
          if (!completer.isCompleted) {
            completer.complete(snap);
          }
        });

        var targetChangeProto = grpc.TargetChange()
          ..targetChangeType = grpc.TargetChange_TargetChangeType.CURRENT
          ..targetIds.add(1);

        mockResponseController.add(
          grpc.ListenResponse()..targetChange = targetChangeProto,
        );

        var snapshot = await completer.future.timeout(
          const Duration(seconds: 2),
        );
        expect(snapshot.exists, isFalse);

        await subscription.cancel();
      },
    );

    test('emits non-existing document snapshot on documentDelete', () async {
      var docRef = firestore.doc('test/doc');
      var completer = Completer<DocumentSnapshot>();
      var subscription = docRef.onGrpcSnapshot().listen((snap) {
        if (!completer.isCompleted) {
          completer.complete(snap);
        }
      });

      var deleteProto = grpc.DocumentDelete()
        ..document =
            'projects/test-project/databases/(default)/documents/test/doc';

      mockResponseController.add(
        grpc.ListenResponse()..documentDelete = deleteProto,
      );

      var snapshot = await completer.future.timeout(const Duration(seconds: 2));
      expect(snapshot.exists, isFalse);

      await subscription.cancel();
    });
  });
}
