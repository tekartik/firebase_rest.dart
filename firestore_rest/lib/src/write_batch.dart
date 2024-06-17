import 'package:tekartik_firebase_firestore/src/firestore_common.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart'; // ignore: implementation_imports

class WriteBatchRestImpl extends WriteBatchBase {
  String? transactionId;
  final FirestoreRestImpl firestoreRestImpl;

  WriteBatchRestImpl(this.firestoreRestImpl) : super();

  @override
  Future commit() async {
    await firestoreRestImpl.commitBatch(this);
  }
}
