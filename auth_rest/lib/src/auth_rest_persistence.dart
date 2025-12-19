import 'package:cv/cv_json.dart';
import 'package:fs_shim/fs_shim.dart';
import 'package:fs_shim/utils/read_write.dart';
import 'package:path/path.dart';
import 'package:tekartik_browser_utils/storage_utils.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';

import 'auth_rest.dart';

/// Access credentials from map
abstract class FirebaseRestAuthPersistenceAccessCredentialsMap
    implements FirebaseRestAuthPersistenceAccessCredentials {
  /// Get user credential
  UserCredentialRest getCredential(AuthProviderRest provider);

  /// Create from map
  factory FirebaseRestAuthPersistenceAccessCredentialsMap(Map map) {
    return _FirebaseRestAuthPersistenceAccessCredentials._(asModel(map));
  }
}

/// Access credentials
class _FirebaseRestAuthPersistenceAccessCredentials
    with FirebaseRestAuthPersistenceAccessCredentialsMixin
    implements FirebaseRestAuthPersistenceAccessCredentialsMap {
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

  @override
  late final bool emailVerified;

  @override
  late final bool isAnonymous;

  @override
  late final String? email;

  @override
  late final String idToken;

  /// Default constructor
  _FirebaseRestAuthPersistenceAccessCredentials._(this._map) {
    uid = _map!['uid'] as String;
    providerId = _map['providerId'] as String;
    emailVerified = _map['emailVerified'] as bool? ?? false;
    isAnonymous = _map['isAnonymous'] as bool? ?? false;
    email = _map['email'] as String?;
    idToken = _map['idToken'] as String? ?? '';
  }

  /// Get user credential for provider
  @override
  UserCredentialRest getCredential(AuthProviderRest provider) {
    var userCredential = UserCredentialRest(
      credential: AuthCredentialRestImpl(),
      user: UserRest(
        emailVerified: emailVerified,
        isAnonymous: isAnonymous,
        uid: uid,
        provider: provider,
      )..email = email,
      idToken: idToken,
    );
    return userCredential;
  }
}

/// Access credentials from user credential
abstract class FirebaseRestAuthPersistenceAccessCredentialsUserCredential
    implements FirebaseRestAuthPersistenceAccessCredentials {
  /// Create from user credential
  factory FirebaseRestAuthPersistenceAccessCredentialsUserCredential({
    required String providerId,
    required UserCredentialRest user,
  }) {
    return _UserCredentialFirebaseRestAuthPersistenceAccessCredentials._(
      providerId,
      user,
    );
  }
}

/// Access credentials
class _UserCredentialFirebaseRestAuthPersistenceAccessCredentials
    with FirebaseRestAuthPersistenceAccessCredentialsMixin
    implements FirebaseRestAuthPersistenceAccessCredentialsUserCredential {
  final UserCredentialRest _userCredential;

  @override
  String get uid => _userCredential.user.uid;
  @override
  final String providerId;

  @override
  String get idToken => _userCredential.idToken;

  /// Default constructor
  _UserCredentialFirebaseRestAuthPersistenceAccessCredentials._(
    this.providerId,
    this._userCredential,
  );

  @override
  String? get email => _userCredential.user.email;

  @override
  bool get emailVerified => _userCredential.user.emailVerified;

  @override
  bool get isAnonymous => _userCredential.user.isAnonymous;
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
    return {
      'uid': uid,
      'providerId': providerId,
      'emailVerified': emailVerified,
      'isAnonymous': isAnonymous,
      'email': email,
      'idToken': idToken,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }
}

/// Access credentials
abstract class FirebaseRestAuthPersistenceAccessCredentials {
  /// Email verified
  bool get emailVerified;

  /// Is anonymous
  bool get isAnonymous;

  /// Email if any
  String? get email;

  /// User id
  String get uid;

  /// Provider id
  String get providerId;

  /// Id token
  String get idToken;

  /// Convert to map
  Model toMap();

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
        return FirebaseRestAuthPersistenceAccessCredentialsMap(map);
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
  final String directoryPath;
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

  File _file(String projectId) =>
      fs.file(join(directoryPath, '$_storageFilePrefix$projectId.json'));

  @override
  Future<FirebaseRestAuthPersistenceAccessCredentials?> get(
    String projectId,
  ) async {
    var file = _file(projectId);
    try {
      if (await file.exists()) {
        var json = await file.readAsString();
        var map = json.jsonToMap();
        return FirebaseRestAuthPersistenceAccessCredentialsMap(map);
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
  final _map = <String, Model>{};

  @override
  Future<FirebaseRestAuthPersistenceAccessCredentials?> get(
    String projectId,
  ) async {
    var map = _map[projectId];
    if (map == null) {
      return null;
    }
    return FirebaseRestAuthPersistenceAccessCredentialsMap(map);
  }

  @override
  Future<void> set(
    String projectId,
    FirebaseRestAuthPersistenceAccessCredentials? credentials,
  ) async {
    if (credentials == null) {
      _map.remove(projectId);
    } else {
      _map[projectId] = credentials.toMap();
    }
  }
}
