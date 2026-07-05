@TestOn('vm')
library;

import 'package:http/http.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

Future main() async {
  var firebase = firebaseRest;
  var name = 'test_generic_app';
  var options = AppOptions(projectId: 'test_generic');
  test('basic', () async {
    var app = firebase.initializeApp(options: options, name: name);
    expect(app.options.projectId, options.projectId);
    expect(app.name, name);
    expect(FirebaseApp.instance.projectId, options.projectId);
    await app.delete();
  });
  test('apiClientStream', () async {
    var app =
        firebase.initializeApp(options: options, name: name) as FirebaseAppRest;
    var client1 = Client();
    var client2 = Client();

    var futureClients = app.apiClientStream.toList();

    // ignore: invalid_use_of_protected_member
    app.client = client1;
    // ignore: invalid_use_of_protected_member
    app.client = client2;

    await app.delete();

    var clients = await futureClients;
    expect(clients, [client1, client2]);
  });
  test('delete reinit', () async {
    var app = firebase.initializeApp(options: options, name: name);
    expect(
      () => firebase.initializeApp(options: options, name: name),
      throwsA(isA<StateError>()),
    );
    await app.delete();
    app = firebase.initializeApp(options: options, name: name);
    await app.delete();
  });
  test('setup', () async {
    var app = firebase.initializeApp(options: options, name: name);

    var app2 = await firebase.initializeAppAsync(
      name: 'app2',
      options: AppOptions(projectId: 'test2'),
    );
    expect(app2.options.projectId, 'test2');
    expect(FirebaseApp.instance.projectId, 'test2');
    await app.delete();
    await app2.delete();
  });
}
