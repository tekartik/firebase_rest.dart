import 'package:cv/cv_json.dart';
import 'package:fs_shim/fs_shim.dart';
import 'package:fs_shim/utils/read_write.dart';
import 'package:tekartik_browser_utils/storage_utils.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';

import 'auth_rest.dart';

/// Access credentials
class _FirebaseRestAuthPersistenceAccessCredentials
    with FirebaseRestAuthPersistenceAccessCredentialsMixin
    implements FirebaseRestAuthPersistenceAccessCredentials {
  final Model? _map;

  /// Convert to map
  @override
  Model toMap() {
    return _map!;
  }

  @override
  late String uid;
  @override
  late String providerId;

  /// Default constructor
  _FirebaseRestAuthPersistenceAccessCredentials._(this._map) {
    uid = _map!['uid'] as String;
    providerId = _map['providerId'] as String;
  }

  UserCredentialRest getCredential(AuthProviderRest provider) {
    var uid = _map!['uid'] as String;

    var userCredential = UserCredentialRest(
      credential: AuthCredentialRestImpl(),
      user: UserRest(
        emailVerified: false,
        isAnonymous: false,
        uid: uid,
        provider: provider,
      ),
      idToken: '',
    );
    return userCredential;
  }
}

/// Access credentials
class _UserCredentialFirebaseRestAuthPersistenceAccessCredentials
    with FirebaseRestAuthPersistenceAccessCredentialsMixin
    implements FirebaseRestAuthPersistenceAccessCredentials {
  final UserCredentialRest _userCredential;

  @override
  String get uid => _userCredential.user.uid;
  @override
  String get providerId => _userCredential.credential.providerId;

  /// Default constructor
  _UserCredentialFirebaseRestAuthPersistenceAccessCredentials._(
    this._userCredential,
  );
}

/// Mixin for access credentials
mixin FirebaseRestAuthPersistenceAccessCredentialsMixin
    implements FirebaseRestAuthPersistenceAccessCredentials {
  @override
  String get uid;

  @override
  String get providerId;

  /// Convert to map
  @override
  Model toMap() {
    return {'uid': uid, 'providerId': providerId};
  }

  @override
  String toString() {
    return toMap().toString();
  }
}

/// Access credentials
abstract class FirebaseRestAuthPersistenceAccessCredentials {
  /// User id
  String get uid;

  /// Provider id
  String get providerId;

  /// Convert to map
  Model toMap();

  /// Create from user credential
  factory FirebaseRestAuthPersistenceAccessCredentials.fromUserCredential(
    UserCredentialRest user,
  ) {
    return _UserCredentialFirebaseRestAuthPersistenceAccessCredentials._(user);
  }

  /// Create from map, catch exception here needed!
  factory FirebaseRestAuthPersistenceAccessCredentials.fromMap(Map map) {
    return _FirebaseRestAuthPersistenceAccessCredentials._(asModel(map));
    /*
    var uid = map['uid'] as String;
    var providerId = map['providerId'] as String?;
    // var providerId = map['providerId'] as String?;
    //
    // var provider = providerId != null ? providers[providerId] : null;
    var userCredential = UserCredentialRest(
      credential: AuthCredentialRestImpl(),
      user: UserRest(
        emailVerified: false,
        isAnonymous: false,
        uid: uid,
        provider: provider,
      ),
      idToken: '',
    );
    return FirebaseRestAuthPersistenceAccessCredentials(
      credential: userCredential,
    );*/
  }

  @override
  String toString() {
    return toMap().toString();
  }
}

/// Persistence interface
abstract class FirebaseRestAuthPersistence {
  /// Get credentials
  Future<FirebaseRestAuthPersistenceAccessCredentials?> get(String projectId);

  /// Set credentials
  Future<void> set(
    String projectId,
    FirebaseRestAuthPersistenceAccessCredentials? credentials,
  );
}

/// Persistence extension
extension FirebaseRestAuthPersistenceExt on FirebaseRestAuthPersistence {
  /// Remove credentials
  Future<void> remove(String projectId) => set(projectId, null);
}

/// Web implementation
class FirebaseRestAuthPersistenceWeb implements FirebaseRestAuthPersistence {
  static const String _storageKeyPrefix =
      'tekartik_firebase_auth_rest_access_credentials_';

  String _key(String projectId) => '$_storageKeyPrefix$projectId';

  @override
  Future<FirebaseRestAuthPersistenceAccessCredentials?> get(
    String projectId,
  ) async {
    try {
      var map = webLocalStorageGet(_key(projectId))?.jsonToMap();
      if (map != null) {
        return FirebaseRestAuthPersistenceAccessCredentials.fromMap(map);
      }
      // Implement web-specific persistence retrieval logic here
    } catch (e) {
      // ignore: avoid_print
      print('Error retrieving credentials from web storage: $e');
    }
    return null;
  }

  @override
  Future<void> set(
    String projectId,
    FirebaseRestAuthPersistenceAccessCredentials? credentials,
  ) async {
    var key = _key(projectId);
    if (credentials == null) {
      webLocalStorageRemove(key);
    } else {
      var map = credentials.toMap().cvToJson();
      webLocalStorageSet(key, map);
    }
  }
}

/// File implementation (cross platform)
class FirebaseRestAuthPersistenceFile implements FirebaseRestAuthPersistence {
  /// The file system to use
  final FileSystem fs;

  /// Optional file system path for saving credentials.
  final String? directoryPath;
  static const _directoryPathDefault = '.local';
  static const String _storageFilePrefix =
      'tekartik_firebase_auth_rest_access_credentials_';

  /// File system based persistence
  FirebaseRestAuthPersistenceFile({
    /// Optional file system
    FileSystem? fs,
    String? directoryPath,
  }) : fs = fs ?? fileSystemDefault,
       directoryPath = directoryPath ?? _directoryPathDefault;

  File _file(String projectId) => fs.file('$_storageFilePrefix$projectId.json');

  @override
  Future<FirebaseRestAuthPersistenceAccessCredentials?> get(
    String projectId,
  ) async {
    var file = _file(projectId);
    try {
      if (await file.exists()) {
        var json = await file.readAsString();
        var map = json.jsonToMap();
        return FirebaseRestAuthPersistenceAccessCredentials.fromMap(map);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error retrieving credentials from file storage: $e');
    }
    return null;
  }

  @override
  Future<void> set(
    String projectId,
    FirebaseRestAuthPersistenceAccessCredentials? credentials,
  ) async {
    var file = _file(projectId);
    if (credentials == null) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error deleting credentials file: $e');
      }
    } else {
      try {
        var raw = credentials.toMap().cvToJson();
        await writeString(file, raw);
      } catch (e) {
        // ignore: avoid_print
        print('Error writing credentials to file: $e');
      }
    }
  }
}

/// File implementation (cross platform)
class FirebaseRestAuthPersistenceMemory implements FirebaseRestAuthPersistence {
  final _map = <String, FirebaseRestAuthPersistenceAccessCredentials>{};

  @override
  Future<FirebaseRestAuthPersistenceAccessCredentials?> get(
    String projectId,
  ) async {
    return _map[projectId];
  }

  @override
  Future<void> set(
    String projectId,
    FirebaseRestAuthPersistenceAccessCredentials? credentials,
  ) async {
    if (credentials == null) {
      _map.remove(projectId);
    } else {
      _map[projectId] = credentials;
    }
  }
}
