import 'package:googleapis/firebaserules/v1.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

import 'firebase_rest.dart';

/// Mixin
mixin FirebaseAppRestMixin {
  /// The http client
  Client? currentAuthClient;
}

/// App Rest
class AppRestImpl
    with FirebaseAppMixin, FirebaseAppRestMixin
    implements FirebaseAppRest {
  /// Firebase rest implementation
  final FirebaseRestImpl firebaseRest;

  @override
  Firebase get firebase => firebaseRest;
  @override
  final AppOptions options;

  /// Deleted flag
  bool deleted = false;
  @override
  late final String name;

  /// App rest implementation.
  AppRestImpl(
      {required this.firebaseRest, required this.options, String? name}) {
    this.name = name ?? firebaseRestDefaultAppName;
    var options = this.options;
    if (options is AppOptionsRest) {
      // Compat
      // ignore: deprecated_member_use_from_same_package
      currentAuthClient = options.client;
    }
  }

  @override
  bool get hasAdminCredentials {
    var options = this.options;

    /// Only true if initializing with a service account
    if (options is FirebaseAppOptionsRest) {
      return (options.identityServiceAccount != null);
    }
    return false;
  }

  @override
  Future<void> delete() async {
    deleted = true;
    await closeServices();
  }

  @override
  @Deprecated('Use client')
  AuthClient? get authClient => currentAuthClient as AuthClient;

  @override
  Client? get client => currentAuthClient;

  @override
  set client(Client? client) => currentAuthClient = client;

  @override
  String toString() {
    return 'FirebaseAppRest($client)';
  }
}

/// Public extension
extension FirebaseAppRestExt on FirebaseAppRest {
  /// Get firestore rules
  Future<String> getFirestoreRules() async {
    var api = FirebaseRulesApi(client!);
    var projectId = options.projectId!;
    var response = await api.projects.rulesets.list('projects/$projectId');
    // print(jsonPretty(response.toJson()));

    var ruleset = response.rulesets!.firstWhere(
        (ruleset) => ruleset.metadata!.services!.contains('cloud.firestore'));
    //print(jsonPretty(ruleset.toJson()));
    var rulesetName = ruleset.name!;
    ruleset = await api.projects.rulesets.get(rulesetName);
    // print(jsonPretty(ruleset.toJson()));
    // {
    //   "createTime": "2021-04-09T10:04:18.835711Z",
    //   "metadata": {
    //     "services": [
    //       "cloud.firestore"
    //     ]
    //   },
    //   "name": "projects/tekartik-free-dev/rulesets/fbdd7bcb-837e-4f96-80d3-c72cddf42811",
    //   "source": {
    //     "files": [
    //       {
    //         "content": "rules_version = '2';\n\nservice cloud.firestore {\n  match /databases/{database}/documents {\n    // Only allow us to read this.\n    match /validate_user_access/{userId} {\n      allow read: if request.auth.uid == userId;\n    }\n    \n    // test access\n    match /test/{test} {\n      match /{documents=**} {\n      \tallow read: if get(/databases/$(database)/documents/test_access/$(test)).data.read == true;\n        allow write: if get(/databases/$(database)/documents/test_access/$(test)).data.write == true;\n      }\n    }\n    \n    // app access\n    match /app/{app} {\n      match /{documents=**} {\n      \tallow read: if get(/databases/$(database)/documents/app_access/$(app)).data.read == true;\n        allow write: if get(/databases/$(database)/documents/app_access/$(app)).data.write == true;\n      }\n    }\n  }\n}",
    //         "name": "firestore.rules"
    //       }
    //     ]
    //   }
    // }
    var content = ruleset.source!.files!.first.content!;
    // print(content);
    return content;
  }
}
