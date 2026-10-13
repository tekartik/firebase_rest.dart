import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart';
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

  /// The authorization metadata of each listen call, in order.
  final authorizations = <String?>[];

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
    authorizations.add(call.clientMetadata?['authorization']);
    late StreamController<grpc.ListenResponse> controller;
    controller = StreamController<grpc.ListenResponse>(
      onCancel: () {
        activeControllers.remove(controller);
      },
    );
    activeControllers.add(controller);
    return controller.stream;
  }

  /// Waits for [count] listen calls.
  Future<void> waitListenCount(int count) async {
    var sw = Stopwatch()..start();
    while (authorizations.length < count) {
      if (sw.elapsed > const Duration(seconds: 5)) {
        throw StateError('${authorizations.length} listen calls');
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
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

/// A signed in user client, handing out its token.
class _TokenClient extends BaseClient implements FirebaseRestTokenClient {
  String token;
  final forceRefreshes = <bool>[];

  _TokenClient(this.token);

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    forceRefreshes.add(forceRefresh);
    if (forceRefresh) {
      token = '${token}r';
    }
    return token;
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) =>
      throw UnimplementedError();
}

grpc.ListenResponse _changeResponse(int seconds) => grpc.ListenResponse()
  ..documentChange = (grpc.DocumentChange()
    ..document = (grpc.Document()
      ..name = 'projects/test-project/databases/(default)/documents/test/doc'
      ..fields['foo'] = (grpc.Value()..stringValue = 'bar')
      ..createTime = (grpc.Timestamp()..seconds = Int64(seconds))
      ..updateTime = (grpc.Timestamp()..seconds = Int64(seconds)))
    ..targetIds.add(1));

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

    test('listens with the token of the signed in user', () async {
      var appRest = app as FirebaseAppRest;
      var client = _TokenClient('u1');
      // ignore: invalid_use_of_protected_member
      appRest.client = client;
      var snapshots = <DocumentSnapshot>[];
      var subscription = firestore
          .doc('test/doc')
          .onSnapshot()
          .listen(snapshots.add);
      await mockService.waitListenCount(1);
      expect(mockService.authorizations, ['Bearer u1']);
      mockService.addResponse(_changeResponse(1));
      while (snapshots.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      // Another user: listens again with its token.
      // ignore: invalid_use_of_protected_member
      appRest.client = _TokenClient('u2');
      await mockService.waitListenCount(2);
      expect(mockService.authorizations.last, 'Bearer u2');

      // Signed out: listens unauthenticated.
      // ignore: invalid_use_of_protected_member
      appRest.client = null;
      await mockService.waitListenCount(3);
      expect(mockService.authorizations.last, isNull);
      expect(mockService.activeControllers, hasLength(1));

      await subscription.cancel();
    });

    test('renews a refused token and listens again', () async {
      var appRest = app as FirebaseAppRest;
      var client = _TokenClient('u1');
      // ignore: invalid_use_of_protected_member
      appRest.client = client;
      var errors = <Object>[];
      var subscription = firestore
          .doc('test/doc')
          .onSnapshot()
          .listen((_) {}, onError: errors.add);
      await mockService.waitListenCount(1);
      mockService.addError(const GrpcError.unauthenticated('expired'));
      await mockService.waitListenCount(2);
      expect(mockService.authorizations, ['Bearer u1', 'Bearer u1r']);
      expect(client.forceRefreshes, [false, true]);
      expect(errors, isEmpty);
      await subscription.cancel();
    });

    test('permission denied ends the stream', () async {
      var errors = <Object>[];
      var done = Completer<void>();
      var subscription = firestore
          .doc('test/doc')
          .onSnapshot()
          .listen((_) {}, onError: errors.add, onDone: done.complete);
      await mockService.waitListenCount(1);
      mockService.addError(const GrpcError.permissionDenied('rules'));
      await done.future.timeout(const Duration(seconds: 2));
      expect(errors.single, isA<GrpcError>());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(mockService.authorizations, hasLength(1));
      await subscription.cancel();
    });

    test('emulator owner listens as owner', () async {
      await (firestore as FirestoreRestImpl).useFirestoreEmulator(
        'localhost',
        server.port!,
        owner: true,
      );
      var subscription = firestore.doc('test/doc').onSnapshot().listen((_) {});
      await mockService.waitListenCount(1);
      expect(mockService.authorizations, ['Bearer owner']);
      await subscription.cancel();
    });
  });
}
