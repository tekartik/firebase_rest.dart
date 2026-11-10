/// Document listeners for the Firestore REST client over gRPC (Dart VM):
/// `firestoreServiceGrpcRest`, a `firestoreServiceRest` whose
/// `DocumentReference.onSnapshot()` works, and the raw
/// `DocumentReference.onGrpcSnapshot()`.
library;

export 'src/firestore_grpc_rest.dart' show DocumentReferenceGrpcRestExt;
export 'src/firestore_grpc_rest_service.dart' show firestoreServiceGrpcRest;
