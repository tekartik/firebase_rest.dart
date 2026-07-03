import 'package:googleapis/firestore/v1.dart' as api;
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_http/http.dart';

/// Rest exception
class FirestoreExceptionRest implements FirestoreException {
  /// Error code
  @override
  late final String code;

  /// Message
  @override
  late final String message;

  /// Details
  @override
  late final Object? details;

  /// Api error
  api.DetailedApiRequestError? apiError;

  /// Constructor
  FirestoreExceptionRest({
    String? code,
    String? message,
    Object? details,
    this.apiError,
  }) {
    if (apiError != null) {
      var foundCode = _map[apiError?.status];
      this.code = code ?? foundCode ?? FirestoreErrorCode.unknown;
      this.message = message ?? apiError?.message ?? 'Unknown error';

      if (foundCode == null) {
        this.message = '$message (${apiError?.status})';
      }
      this.details = details ?? apiError?.errors;
    } else {
      this.code = code ?? FirestoreErrorCode.unknown;
      this.message = message ?? 'Unknown error';
      this.details = details;
    }
  }
  @override
  String toString() {
    return 'FirestoreExeptionRest{code: $code, message: $message, details: $details, apiError: $apiError}';
  }
}

var _map = {
  httpStatusCodeNotFound: FirestoreErrorCode.notFound,
  httpStatusCodeUnauthorized: FirestoreErrorCode.unauthenticated,
  httpStatusCodeForbidden: FirestoreErrorCode.permissionDenied,
  httpStatusCodeInternalServerError: FirestoreErrorCode.internal,
};
