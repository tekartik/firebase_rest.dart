import 'dart:async';
import 'dart:io';

import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  stdout.writeln('http://localhost:8060/example_auth.html');
  await shell.run('''
  
  dart pub global run webdev serve example:8060 --auto=refresh
  
  ''');
}
