import 'package:googleapis/firestore/v1.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart'; // ignore: implementation_imports
export 'package:tekartik_firebase_firestore/firestore.dart';
export 'src/firestore_rest_impl.dart' show debugFirestoreRest;

/// Rest firestore service.
abstract class FirestoreServiceRest extends FirestoreService {}

/// Global service.
FirestoreServiceRest firestoreServiceRest = FirestoreServiceRestImpl();

/// Needed for firestore database access
const String firestoreGoogleApisAuthDatastoreScope =
    FirestoreApi.datastoreScope;

/// Deprecated for typo
@Deprecated('Use firestoreGoogleApisAuthDatastoreScope')
const String googleApisAuthDatastoreScopre =
    firestoreGoogleApisAuthDatastoreScope;

/// Deprecated to match other names.
@Deprecated('Use firestoreGoogleApisAuthCloudPlatformScope')
const String googleApisAuthCloudPlatformScope =
    firestoreGoogleApisAuthCloudPlatformScope;

/// Needed for firestore cloud platform access
const String firestoreGoogleApisAuthCloudPlatformScope =
    FirestoreApi.cloudPlatformScope;
