@TestOn('vm')
library;

import 'dart:io';
import 'package:dev_build/shell.dart';
import 'package:tekartik_firebase_emulator/firebase_emulator.dart';
import 'package:test/test.dart';

var _emulatorService = FirebaseEmulatorService(path: 'emulator');
Future main() async {
  if (await _emulatorService.isSupported()) {
    stdout.writeln('firebase emulator is supported');
  } else {
    stderr.writeln('firebase emulator not supported');

    return;
  }

  final fbProjectId = await _emulatorService.getProjectId();
  var emulator = await _emulatorService.start(
    options: FirebaseEmulatorOptions(
      projectId: fbProjectId,
      onlyFirestore: true,
      onlyAuth: true,
      debug: false,
      persistPath: '.data',
    ),
  );

  stdout.writeln('Emulator started');
  await prompt('Press enter to stop the emulator');
  await emulator.stop();
  stdout.writeln('Emulator stopped');
  await promptTerminate();
}
