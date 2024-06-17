import 'package:dev_build/package.dart';
import 'package:path/path.dart';

var topDir = '..';

Future<void> main() async {
  for (var dir in [
    'firebase_rest',
    'auth_rest',
    'storage_rest',
    'firestore_rest',
  ]) {
    await packageRunCi(join(topDir, dir));
  }
}
