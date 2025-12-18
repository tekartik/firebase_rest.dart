// ignore_for_file: directives_ordering, avoid_print

import 'dart:io';

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest_io.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart';

Future<void> main() async {
  var authService = firebaseAuthServiceRest;
  var options = GoogleAuthOptions.fromMap(
    loadYaml(await File(join('example', 'local.config_io.yaml')).readAsString())
        as Map,
  );
  var app = firebaseRest.initializeApp(
    options: AppOptionsRest()
      ..projectId = options.projectId
      ..apiKey = options.apiKey,
  );
  var provider = GoogleAuthProviderRestIo(
    options: options,
    credentialPath: join('example', 'local.config_io.user.credentials.yaml'),
  );
  var auth = authService.auth(app);
  auth.addProvider(provider);
  var currentUser = await auth.onCurrentUser.first;
  if (currentUser == null) {
    var result = await auth.signIn(provider);
    print(result);
    currentUser = result.credential?.user;
    print(options);
  }
  print('currentUser: $currentUser');
  print('applicationDefault: ${firebaseRest.credential.applicationDefault()}');
}
