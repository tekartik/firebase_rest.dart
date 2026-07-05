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

  final activeControllers = <StreamController<grpc.ListenResponse>>[];

  MockFirestoreService() {
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
    late StreamController<grpc.ListenResponse> controller;
    controller = StreamController<grpc.ListenResponse>(
      onCancel: () {
        activeControllers.remove(controller);
      },
    );
    activeControllers.add(controller);
    return controller.stream;
  }

  Future<void> get hasListener async {
    while (activeControllers.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  void addResponse(grpc.ListenResponse response) {
    for (var controller in List<StreamController<grpc.ListenResponse>>.from(
      activeControllers,
    )) {
      controller.add(response);
    }
  }

  void addError(Object error) {
    for (var controller in List<StreamController<grpc.ListenResponse>>.from(
      activeControllers,
    )) {
      controller.addError(error);
    }
  }

  Future<void> close() async {
    for (var controller in List<StreamController<grpc.ListenResponse>>.from(
      activeControllers,
    )) {
      await controller.close();
    }
    activeControllers.clear();
  }
}

void main() {
  group('onGrpcSnapshot', () {
    late Server server;
    late MockFirestoreService mockService;
    late FirebaseApp app;
    late Firestore firestore;

    setUp(() async {
      mockService = MockFirestoreService();
      server = Server.create(services: [mockService]);
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
      await mockService.close();
    });

    test('emits document snapshots on documentChange', () async {
      var docRef = firestore.doc('test/doc');
      var completer = Completer<DocumentSnapshot>();
      var subscription = docRef.onGrpcSnapshot().listen((snap) {
        if (!completer.isCompleted) {
          completer.complete(snap);
        }
      });

      await mockService.hasListener;

      // Send initial documentChange via gRPC mock service
      var docProto = grpc.Document()
        ..name = 'projects/test-project/databases/(default)/documents/test/doc'
        ..fields['foo'] = (grpc.Value()..stringValue = 'bar')
        ..createTime = (grpc.Timestamp()..seconds = Int64(123456789))
        ..updateTime = (grpc.Timestamp()..seconds = Int64(123456789));

      var changeProto = grpc.DocumentChange()
        ..document = docProto
        ..targetIds.add(1);

      mockService.addResponse(
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

        await mockService.hasListener;

        var targetChangeProto = grpc.TargetChange()
          ..targetChangeType = grpc.TargetChange_TargetChangeType.CURRENT
          ..targetIds.add(1);

        mockService.addResponse(
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

      await mockService.hasListener;

      var deleteProto = grpc.DocumentDelete()
        ..document =
            'projects/test-project/databases/(default)/documents/test/doc';

      mockService.addResponse(
        grpc.ListenResponse()..documentDelete = deleteProto,
      );

      var snapshot = await completer.future.timeout(const Duration(seconds: 2));
      expect(snapshot.exists, isFalse);

      await subscription.cancel();
    });
  });

  group('firestoreServiceGrpcRest', () {
    late Server server;
    late MockFirestoreService mockService;
    late FirebaseApp app;
    late Firestore firestore;

    setUp(() async {
      mockService = MockFirestoreService();
      server = Server.create(services: [mockService]);
      await server.serve(address: 'localhost', port: 0);

      app = firebaseRest.initializeApp(
        options: AppOptionsRest()..projectId = 'test-project',
      );
      firestore = firestoreServiceGrpcRest.firestore(app);
      await (firestore as FirestoreRestImpl).useFirestoreEmulator(
        'localhost',
        server.port!,
      );
    });

    tearDown(() async {
      await app.delete();
      await server.shutdown();
      await mockService.close();
    });

    test('onSnapshot emits document snapshots on documentChange', () async {
      var docRef = firestore.doc('test/doc');
      var completer = Completer<DocumentSnapshot>();
      var subscription = docRef.onSnapshot().listen((snap) {
        if (!completer.isCompleted) {
          completer.complete(snap);
        }
      });

      await mockService.hasListener;

      // Send initial documentChange via gRPC mock service
      var docProto = grpc.Document()
        ..name = 'projects/test-project/databases/(default)/documents/test/doc'
        ..fields['foo'] = (grpc.Value()..stringValue = 'bar')
        ..createTime = (grpc.Timestamp()..seconds = Int64(123456789))
        ..updateTime = (grpc.Timestamp()..seconds = Int64(123456789));

      var changeProto = grpc.DocumentChange()
        ..document = docProto
        ..targetIds.add(1);

      mockService.addResponse(
        grpc.ListenResponse()..documentChange = changeProto,
      );

      var snapshot = await completer.future.timeout(const Duration(seconds: 2));
      expect(snapshot.exists, isTrue);
      expect(snapshot.data, {'foo': 'bar'});

      await subscription.cancel();
    });

    test('reconnects and retries on transient connection error', () async {
      var docRef = firestore.doc('test/doc');
      var snapshots = <DocumentSnapshot>[];
      var subscription = docRef.onSnapshot().listen(snapshots.add);

      await mockService.hasListener;

      // 1. Send first change
      var docProto = grpc.Document()
        ..name = 'projects/test-project/databases/(default)/documents/test/doc'
        ..fields['foo'] = (grpc.Value()..stringValue = 'bar')
        ..createTime = (grpc.Timestamp()..seconds = Int64(123456789))
        ..updateTime = (grpc.Timestamp()..seconds = Int64(123456789));

      var changeProto = grpc.DocumentChange()
        ..document = docProto
        ..targetIds.add(1);

      mockService.addResponse(
        grpc.ListenResponse()..documentChange = changeProto,
      );

      // Wait for first snapshot
      while (snapshots.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(snapshots.last.data, {'foo': 'bar'});

      // 2. Trigger connection error (non-permission)
      mockService.addError(const GrpcError.unavailable('Connection lost'));

      // Wait for activeControllers to become empty (the first connection has closed)
      while (mockService.activeControllers.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      // 3. Wait for the reconnect connection to establish
      await mockService.hasListener;

      var docProto2 = grpc.Document()
        ..name = 'projects/test-project/databases/(default)/documents/test/doc'
        ..fields['foo'] = (grpc.Value()..stringValue = 'baz')
        ..createTime = (grpc.Timestamp()..seconds = Int64(123456790))
        ..updateTime = (grpc.Timestamp()..seconds = Int64(123456790));

      var changeProto2 = grpc.DocumentChange()
        ..document = docProto2
        ..targetIds.add(1);

      mockService.addResponse(
        grpc.ListenResponse()..documentChange = changeProto2,
      );

      // Wait for second snapshot
      while (snapshots.length < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(snapshots.last.data, {'foo': 'baz'});

      await subscription.cancel();
    });
  });
}
