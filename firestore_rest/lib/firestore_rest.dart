import 'package:googleapis/firestore/v1.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1_fixed.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart'; // ignore: implementation_imports

abstract class FirestoreServiceRest extends FirestoreService {}

FirestoreServiceRest firestoreServiceRest = FirestoreServiceRestImpl();

/// Needed for firestore database access
const String firestoreGoogleApisAuthDatastoreScope =
    FirestoreApi.datastoreScope;

@Deprecated('Use firestoreGoogleApisAuthDatastoreScope')
const String googleApisAuthDatastoreScopre =
    firestoreGoogleApisAuthDatastoreScope;
@Deprecated('Use firestoreGoogleApisAuthCloudPlatformScope')
const String googleApisAuthCloudPlatformScope =
    firestoreGoogleApisAuthCloudPlatformScope;

const String firestoreGoogleApisAuthCloudPlatformScope =
    FirestoreApi.cloudPlatformScope;
