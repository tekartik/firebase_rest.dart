/// Cloud Storage over the Google REST API, on an app of
/// `tekartik_firebase_rest`: [firebaseStorageServiceRest] then
/// `storage(app)`, or [FirebaseStorageRest.fromAuthClient] without an app.
///
/// Public download urls without credentials are in `storage_json.dart`.
library;

export 'package:tekartik_firebase_storage/storage.dart';

export 'src/storage_rest_impl.dart'
    show
        FirebaseStorageServiceRest,
        firebaseStorageServiceRest,
        FirebaseStorageRest,
        firebaseStorageGoogleApisReadWriteScope,
        // compat
        StorageRest,
        StorageServiceRest,
        storageServiceRest,
        storageGoogleApisReadWriteScope;
