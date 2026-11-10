import 'dart:async';
import 'dart:convert';

import 'package:tekartik_firebase_functions/firebase_functions.dart'
    show HttpsError, HttpsErrorCode;
import 'package:tekartik_firebase_functions_call_rest/functions_call_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  var never = Completer<void>();
  var options = FirebaseFunctionsCallOptions(region: regionBelgium);

  setUpAll(() async {
    server = await httpServerFactoryMemory.bind(InternetAddress.anyIPv4, 0);
    server.listen((request) async {
      if (request.uri.path == '/never') {
        // Never answered while the test runs.
        await never.future;
      }
      request.response.headers.set(httpHeaderContentType, httpContentTypeJson);
      request.response.write(jsonEncode({'result': 'ok'}));
      await request.response.close();
    });
  });
  tearDownAll(() async {
    never.complete();
    await server.close(force: true);
  });

  /// A rest app calling with [client] (as a signed in user's client).
  FirebaseAppRest newApp(String name, Client client) =>
      firebaseRest.initializeApp(
            name: name,
            options: FirebaseAppOptionsRest(client: client),
          )
          as FirebaseAppRest;

  Uri uri(String path) => httpServerGetUri(server).replace(path: path);

  test('an app re-created with the same name calls with its client', () async {
    var client1 = httpClientFactoryMemory.newClient();
    var app1 = newApp('same_name', client1);
    var functionsCall1 = firebaseFunctionsCallServiceRest.functionsCall(
      app1,
      options: options,
    );
    expect(
      firebaseFunctionsCallServiceRest.functionsCall(app1, options: options),
      same(functionsCall1),
    );
    expect(
      (await functionsCall1.callableFromUri(uri('/ok')).call<String>()).data,
      'ok',
    );
    await app1.delete();
    client1.close();

    var client2 = httpClientFactoryMemory.newClient();
    addTearDown(client2.close);
    var app2 = newApp('same_name', client2);
    addTearDown(app2.delete);
    var functionsCall2 = firebaseFunctionsCallServiceRest.functionsCall(
      app2,
      options: options,
    );
    expect(functionsCall2, isNot(same(functionsCall1)));
    expect(functionsCall2.app, same(app2));
    // The old app's client is closed: the call must not use it.
    expect(
      (await functionsCall2.callableFromUri(uri('/ok')).call<String>()).data,
      'ok',
    );
  });

  test('the callable timeout is applied', () async {
    var client = httpClientFactoryMemory.newClient();
    addTearDown(client.close);
    var app = newApp('timeout', client);
    addTearDown(app.delete);
    var callable = firebaseFunctionsCallServiceRest
        .functionsCall(app, options: options)
        .callableFromUri(
          uri('/never'),
          options: FirebaseFunctionsCallableOptions(
            timeout: const Duration(milliseconds: 200),
          ),
        );
    try {
      await callable.call<Object?>().timeout(const Duration(seconds: 10));
      fail('should fail');
    } on HttpsError catch (e) {
      expect(e.code, HttpsErrorCode.deadlineExceeded);
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}
