// ignore_for_file: avoid_print

import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

import '../../test/test_setup.dart';

Future<void> main(List<String> args) async {
  var context = await authRestSetup(useEnv: true);
  if (context == null) {
    print('no env setup available');
  } else {
    var app = context.app; //, options: context?.options);
    var auth = firebaseAuthServiceRest.auth(app);
    var currentUser = await auth.onCurrentUser.first;
    print('Using firebase:');
    print('currentUser: $currentUser');
    print('projectId: ${context.options!.projectId}');
    print(
      'applicationDefault: ${firebaseRest.credential.applicationDefault()}',
    );
    await app.delete();
  }
}
