import 'dart:async';

import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  print('http://localhost:8060/example_auth.html');
  await shell.run('''
  
  dart pub global run webdev serve example:8060 --auto=refresh
  
  ''');
}
