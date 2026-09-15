import 'dart:async';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart'
    show UserCredentialRest;
import 'package:tekartik_firebase_auth_rest/src/email_password_auth_rest.dart';
import 'package:test/test.dart';

/// Only the tokens matter to the client.
class _Credential implements UserCredentialRest {
  @override
  final RestAuthTokens tokens;

  _Credential(this.tokens);

  @override
  String get idToken => tokens.idToken;

  @override
  AuthCredential get credential => throw UnimplementedError();

  @override
  FirebaseUser get user => throw UnimplementedError();
}

void main() {
  group('LoggedInClient', () {
    late List<String?> sentAuthorizations;
    late List<int> statuses;
    late List<bool> refreshes;

    /// [statuses] are answered in order, the last one repeated.
    MockClient inner() => MockClient((request) async {
      sentAuthorizations.add(request.headers['Authorization']);
      var status = statuses.length > 1
          ? statuses.removeAt(0)
          : statuses.first;
      return Response('body', status);
    });

    setUp(() {
      sentAuthorizations = [];
      statuses = [200];
      refreshes = [];
    });

    RestAuthTokens tokens({bool refreshable = true, DateTime? expiresAt}) =>
        RestAuthTokens(
          idToken: 't1',
          refreshToken: refreshable ? 'r1' : null,
          expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 1)),
        );

    LoggedInClient client(RestAuthTokens tokens) => LoggedInClient(
      inner: inner(),
      userCredential: _Credential(tokens),
      refreshToken: ({bool force = false}) async {
        refreshes.add(force);
        tokens.idToken = 't${refreshes.length + 1}';
        tokens.expiresAt = DateTime.now().add(const Duration(hours: 1));
      },
    );

    test('valid token is sent as is', () async {
      var response = await client(tokens()).get(Uri.parse('http://x/y'));
      expect(response.statusCode, 200);
      expect(sentAuthorizations, ['Bearer t1']);
      expect(refreshes, isEmpty);
    });

    test('expiring token is renewed before the request', () async {
      var response = await client(
        tokens(expiresAt: DateTime.now().add(const Duration(minutes: 2))),
      ).get(Uri.parse('http://x/y'));
      expect(response.statusCode, 200);
      expect(refreshes, [false]);
      expect(sentAuthorizations, ['Bearer t2']);
    });

    test('401 renews once and retries', () async {
      statuses = [401, 200];
      var response = await client(tokens()).post(
        Uri.parse('http://x/y'),
        body: '{"a":1}',
      );
      expect(response.statusCode, 200);
      expect(response.body, 'body');
      expect(refreshes, [true]);
      expect(sentAuthorizations, ['Bearer t1', 'Bearer t2']);
    });

    test('401 twice is returned', () async {
      statuses = [401];
      var response = await client(tokens()).get(Uri.parse('http://x/y'));
      expect(response.statusCode, 401);
      expect(refreshes, [true]);
      expect(sentAuthorizations, ['Bearer t1', 'Bearer t2']);
    });

    test('no refresh token: 401 is returned, no renewal', () async {
      statuses = [401];
      var response = await client(
        tokens(refreshable: false),
      ).get(Uri.parse('http://x/y'));
      expect(response.statusCode, 401);
      expect(refreshes, isEmpty);
      expect(sentAuthorizations, ['Bearer t1']);
    });

    test('no refresh callback: 401 is returned', () async {
      statuses = [401];
      var response = await LoggedInClient(
        inner: inner(),
        userCredential: _Credential(tokens()),
      ).get(Uri.parse('http://x/y'));
      expect(response.statusCode, 401);
      expect(sentAuthorizations, ['Bearer t1']);
    });

    test('streamed body of unknown length is not retried', () async {
      statuses = [401];
      var request = StreamedRequest('POST', Uri.parse('http://x/y'));
      unawaited(
        Future(() {
          request.sink.add([1, 2, 3]);
          request.sink.close();
        }),
      );
      var response = await client(tokens()).send(request);
      expect(response.statusCode, 401);
      expect(refreshes, isEmpty);
      expect(sentAuthorizations, ['Bearer t1']);
    });

    test('refused renewal propagates', () async {
      statuses = [401];
      var tokens0 = tokens();
      var client = LoggedInClient(
        inner: inner(),
        userCredential: _Credential(tokens0),
        refreshToken: ({bool force = false}) async {
          throw RestAuthTokenRefreshException(
            statusCode: 400,
            code: 'TOKEN_EXPIRED',
            message: 'TOKEN_EXPIRED',
          );
        },
      );
      expect(
        () => client.get(Uri.parse('http://x/y')),
        throwsA(isA<RestAuthTokenRefreshException>()),
      );
    });
  });
}
