import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:test/test.dart';

/// A fake jwt with the given `exp` claim (seconds since epoch).
String fakeJwt({required int exp}) {
  String part(Object json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part({'exp': exp, 'sub': 'u1'})}.sig';
}

void main() {
  group('RestAuthTokens', () {
    test('fromSignIn expiresIn', () {
      var now = DateTime(2026, 9, 15, 12);
      var tokens = RestAuthTokens.fromSignIn(
        idToken: 'id',
        refreshToken: 'refresh',
        expiresIn: '3600',
        now: now,
      );
      expect(tokens.expiresAt, now.add(const Duration(hours: 1)));
      expect(tokens.canRefresh, isTrue);
      expect(tokens.isExpiring(now: now), isFalse);
      expect(
        tokens.isExpiring(now: now.add(const Duration(minutes: 56))),
        isTrue,
      );
      expect(tokens.isExpired(now: now.add(const Duration(minutes: 59))), isFalse);
      expect(tokens.isExpired(now: now.add(const Duration(minutes: 60))), isTrue);
    });

    test('fromSignIn falls back to the jwt exp', () {
      var exp = DateTime(2026, 9, 15, 13, 1, 44);
      var tokens = RestAuthTokens.fromSignIn(
        idToken: fakeJwt(exp: exp.millisecondsSinceEpoch ~/ 1000),
      );
      expect(tokens.expiresAt, exp);
      expect(tokens.canRefresh, isFalse);
    });

    test('unknown expiration never expires', () {
      var tokens = RestAuthTokens(idToken: 'not-a-jwt');
      expect(tokens.expiration, isNull);
      expect(tokens.isExpiring(), isFalse);
      expect(tokens.isExpired(), isFalse);
    });

    test('update keeps the refresh token when none is sent', () {
      var tokens = RestAuthTokens(idToken: 'id1', refreshToken: 'r1');
      tokens.update(RestAuthTokens(idToken: 'id2', expiresAt: DateTime(2030)));
      expect(tokens.idToken, 'id2');
      expect(tokens.refreshToken, 'r1');
      expect(tokens.expiresAt, DateTime(2030));
      tokens.update(RestAuthTokens(idToken: 'id3', refreshToken: 'r2'));
      expect(tokens.refreshToken, 'r2');
    });
  });

  group('idTokenExpiration', () {
    test('jwt', () {
      var exp = DateTime(2026, 9, 15, 13, 1, 44);
      expect(
        idTokenExpiration(fakeJwt(exp: exp.millisecondsSinceEpoch ~/ 1000)),
        exp,
      );
    });
    test('not a jwt', () {
      expect(idTokenExpiration('mock_id_token'), isNull);
      expect(idTokenExpiration('a.b.c'), isNull);
      expect(idTokenExpiration(''), isNull);
    });
  });

  group('RestAuthTokenRefresher', () {
    test('uri', () {
      expect(
        RestAuthTokenRefresher(apiKey: 'k').uri.toString(),
        'https://securetoken.googleapis.com/v1/token?key=k',
      );
      expect(
        RestAuthTokenRefresher(
          apiKey: 'k',
          rootUrl: 'http://localhost:9099/',
        ).uri.toString(),
        'http://localhost:9099/securetoken.googleapis.com/v1/token?key=k',
      );
      expect(
        RestAuthTokenRefresher(
          apiKey: 'k',
          rootUrl: 'http://localhost:9099',
        ).uri.toString(),
        'http://localhost:9099/securetoken.googleapis.com/v1/token?key=k',
      );
    });

    test('refresh', () async {
      Request? sent;
      var refresher = RestAuthTokenRefresher(
        apiKey: 'k',
        clientFactory: () => MockClient((request) async {
          sent = request;
          return Response(
            jsonEncode({
              'access_token': 'a',
              'expires_in': '3600',
              'token_type': 'Bearer',
              'refresh_token': 'r2',
              'id_token': 'id2',
              'user_id': 'u1',
              'project_id': 'p',
            }),
            200,
          );
        }),
      );
      var before = DateTime.now();
      var tokens = await refresher.refresh('r1');
      expect(sent!.method, 'POST');
      expect(
        sent!.url.toString(),
        'https://securetoken.googleapis.com/v1/token?key=k',
      );
      expect(sent!.bodyFields, {
        'grant_type': 'refresh_token',
        'refresh_token': 'r1',
      });
      expect(tokens.idToken, 'id2');
      expect(tokens.refreshToken, 'r2');
      expect(
        tokens.expiresAt!.difference(before).inMinutes,
        inInclusiveRange(59, 60),
      );
    });

    test('refresh keeps the refresh token when none is sent', () async {
      var refresher = RestAuthTokenRefresher(
        apiKey: 'k',
        clientFactory: () => MockClient(
          (request) async =>
              Response(jsonEncode({'id_token': 'id2', 'expires_in': '10'}), 200),
        ),
      );
      var tokens = await refresher.refresh('r1');
      expect(tokens.refreshToken, 'r1');
    });

    test('refused', () async {
      var refresher = RestAuthTokenRefresher(
        apiKey: 'k',
        clientFactory: () => MockClient(
          (request) async => Response(
            jsonEncode({
              'error': {
                'code': 400,
                'message': 'TOKEN_EXPIRED',
                'status': 'INVALID_ARGUMENT',
              },
            }),
            400,
          ),
        ),
      );
      try {
        await refresher.refresh('r1');
        fail('should fail');
      } on RestAuthTokenRefreshException catch (e) {
        expect(e.statusCode, 400);
        expect(e.code, 'TOKEN_EXPIRED');
        expect(e.isSessionExpired, isTrue);
      }
    });

    test('server error is transient', () async {
      var refresher = RestAuthTokenRefresher(
        apiKey: 'k',
        clientFactory: () =>
            MockClient((request) async => Response('oops', 503)),
      );
      try {
        await refresher.refresh('r1');
        fail('should fail');
      } on RestAuthTokenRefreshException catch (e) {
        expect(e.statusCode, 503);
        expect(e.code, isNull);
        expect(e.isSessionExpired, isFalse);
      }
    });
  });
}
