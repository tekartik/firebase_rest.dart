import 'package:tekartik_common_utils/out_buffer.dart';
import 'package:web/web.dart';

OutBuffer _outBuffer = OutBuffer(100);
Element? _output = document.getElementById('output');

void write([Object? message]) {
  print(message);
  _output!.textContent = (_outBuffer..add('$message')).toString();
}
