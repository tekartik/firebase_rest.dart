// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  var dir = Directory('lib/src/generated');
  if (!dir.existsSync()) {
    print('Directory not found: ${dir.path}');
    return;
  }

  // 1. Delete the local copy of the google/protobuf directory (well-known types)
  var protobufDir = Directory('lib/src/generated/google/protobuf');
  if (protobufDir.existsSync()) {
    protobufDir.deleteSync(recursive: true);
    print('Deleted local google/protobuf well-known types.');
  }

  // Regex to match any relative import pointing to a protobuf/ directory
  var protobufImportRegex = RegExp(
    'import\\s+[\'"]\\.\\.?/.*?protobuf/(.*?\\.dart)[\'"]',
  );

  // Regex to match createRepeated() methods
  var createRepeatedRegex = RegExp(
    r'static\s+\$pb\.(?:PbList|newPbList)<[^>]+>\s+createRepeated\(\)[\s\S]*?;',
  );

  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      var original = content;

      // 2. Redirect well-known types imports to package:protobuf/well_known_types/...
      content = content.replaceAllMapped(protobufImportRegex, (match) {
        var filename = match.group(1);
        return "import 'package:protobuf/well_known_types/google/protobuf/$filename'";
      });

      // 3. Remove createRepeated methods entirely from .pb.dart files
      if (entity.path.endsWith('.pb.dart')) {
        content = content.replaceAll(createRepeatedRegex, '');
      }

      if (content != original) {
        entity.writeAsStringSync(content);
        print('Patched imports/methods in: ${entity.path}');
      }
    }
  });
  print('Done patching generated files.');
}
