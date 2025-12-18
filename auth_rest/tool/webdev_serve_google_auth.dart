import 'dart:async';
import 'dart:io';

import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();
  var port = 8060;
  port = 8081;
  stdout.writeln('http://localhost:$port/example_google_auth.html');
  await shell.run('''
  
  dart pub global run webdev serve example:$port --auto=refresh
  
  ''');
}
