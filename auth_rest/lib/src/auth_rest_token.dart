import 'dart:convert';

import 'package:http/http.dart';

/// The tokens of a user signed in through the identity toolkit: the id token
/// sent as bearer to the firebase apis, the refresh token that renews it and
/// when the id token expires.
///
/// Mutable: a refresh updates the instance in place, so a client holding it
/// sends the new token from then on.
class RestAuthTokens {
  /// The id token (a jwt, valid for an hour).
  String idToken;

  /// The refresh token, null when the provider did not hand out one, in which
  /// case the id token cannot be renewed.
  String? refreshToken;

  /// When the id token expires, null when unknown.
  DateTime? expiresAt;

  /// Tokens.
  RestAuthTokens({required this.idToken, this.refreshToken, this.expiresAt});

  /// From a sign in (or refresh) response: [expiresIn] is a duration in
  /// seconds, as the identity toolkit sends it. Falls back to the `exp` claim
  /// of the id token.
  factory RestAuthTokens.fromSignIn({
    required String idToken,
    String? refreshToken,
    String? expiresIn,
    DateTime? now,
  }) {
    DateTime? expiresAt;
    var seconds = int.tryParse(expiresIn ?? '');
    if (seconds != null) {
      expiresAt = (now ?? DateTime.now()).add(Duration(seconds: seconds));
    }
    return RestAuthTokens(
      idToken: idToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt ?? idTokenExpiration(idToken),
    );
  }

  /// When the id token expires: [expiresAt], or the `exp` claim of the token.
  DateTime? get expiration => expiresAt ?? idTokenExpiration(idToken);

  /// Whether the id token can be renewed.
  bool get canRefresh => refreshToken != null;

  /// Whether the id token is expired or expires within [margin].
  ///
  /// False when the expiration is unknown.
  bool isExpiring({
    Duration margin = const Duration(minutes: 5),
    DateTime? now,
  }) {
    var expiration = this.expiration;
    if (expiration == null) {
      return false;
    }
    return !(now ?? DateTime.now()).isBefore(expiration.subtract(margin));
  }

  /// Whether the id token is expired.
  bool isExpired({DateTime? now}) =>
      isExpiring(margin: Duration.zero, now: now);

  /// Take the tokens of a refresh (a refresh may or may not send a new
  /// refresh token).
  void update(RestAuthTokens other) {
    idToken = other.idToken;
    refreshToken = other.refreshToken ?? refreshToken;
    expiresAt = other.expiresAt;
  }

  @override
  String toString() =>
      'RestAuthTokens(expiresAt: $expiresAt, canRefresh: $canRefresh)';
}

/// The expiration of a jwt from its `exp` claim, null if [idToken] is not one.
DateTime? idTokenExpiration(String idToken) {
  try {
    var parts = idToken.split('.');
    if (parts.length != 3) {
      return null;
    }
    var payload =
        json.decode(
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
            )
            as Map;
    var exp = payload['exp'];
    if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    }
  } catch (_) {
    // Not a jwt.
  }
  return null;
}

/// A refresh failed.
class RestAuthTokenRefreshException implements Exception {
  /// The http status, 400 when the refresh token is not accepted anymore.
  final int statusCode;

  /// The error code sent by the api (`TOKEN_EXPIRED`, `USER_NOT_FOUND`,
  /// `INVALID_REFRESH_TOKEN`, `USER_DISABLED`...), if any.
  final String? code;

  /// The message.
  final String message;

  /// A refresh failed.
  RestAuthTokenRefreshException({
    required this.statusCode,
    this.code,
    required this.message,
  });

  /// Whether the session is over: the refresh token is not accepted anymore
  /// and the user must sign in again. Anything else (network, server) is
  /// transient.
  bool get isSessionExpired =>
      statusCode == 400 || statusCode == 401 || statusCode == 403;

  @override
  String toString() =>
      'RestAuthTokenRefreshException($statusCode'
      '${code != null ? ' $code' : ''}: $message)';
}

/// Renews an id token through the secure token api
/// (`securetoken.googleapis.com/v1/token`), or its auth emulator route.
class RestAuthTokenRefresher {
  /// The api key of the app.
  final String apiKey;

  /// The auth emulator root (`http://localhost:9099/`), null for the real api.
  final String? rootUrl;

  /// The http client factory, a new default client per call otherwise.
  final Client Function()? clientFactory;

  /// Renews an id token.
  RestAuthTokenRefresher({
    required this.apiKey,
    this.rootUrl,
    this.clientFactory,
  });

  /// The token endpoint.
  Uri get uri {
    var root = rootUrl;
    String base;
    if (root == null) {
      base = 'https://securetoken.googleapis.com/';
    } else {
      base =
          '${root.endsWith('/') ? root : '$root/'}securetoken.googleapis.com/';
    }
    return Uri.parse(
      '${base}v1/token',
    ).replace(queryParameters: {'key': apiKey});
  }

  /// Exchange [refreshToken] for a new id token (and possibly a new refresh
  /// token).
  Future<RestAuthTokens> refresh(String refreshToken) async {
    var client = (clientFactory ?? Client.new)();
    try {
      var now = DateTime.now();
      var response = await client.post(
        uri,
        body: {'grant_type': 'refresh_token', 'refresh_token': refreshToken},
      );
      Object? decoded;
      try {
        decoded = json.decode(response.body);
      } catch (_) {
        // Not json.
      }
      if (response.statusCode != 200) {
        var message = response.reasonPhrase ?? 'error';
        String? code;
        if (decoded is Map) {
          var error = decoded['error'];
          if (error is Map) {
            message = error['message']?.toString() ?? message;
            code = RegExp(r'^[A-Z][A-Z0-9_]+').stringMatch(message);
          }
        }
        throw RestAuthTokenRefreshException(
          statusCode: response.statusCode,
          code: code,
          message: message,
        );
      }
      var map = decoded is Map ? decoded : const <String, Object?>{};
      var idToken = map['id_token'] as String?;
      if (idToken == null) {
        throw RestAuthTokenRefreshException(
          statusCode: response.statusCode,
          message: 'missing id_token in ${response.body}',
        );
      }
      return RestAuthTokens.fromSignIn(
        idToken: idToken,
        refreshToken: map['refresh_token'] as String? ?? refreshToken,
        expiresIn: map['expires_in']?.toString(),
        now: now,
      );
    } finally {
      client.close();
    }
  }
}
