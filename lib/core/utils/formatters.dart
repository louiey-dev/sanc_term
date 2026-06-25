import 'dart:convert';
import 'dart:typed_data';

final _ansiEscape = RegExp(r'\x1b\[[0-?]*[ -/]*[@-~]');

String stripAnsi(String input) => input.replaceAll(_ansiEscape, '');

String listIntToString(List<int> list) => utf8.decode(list);

List<int> stringToListInt(String str) => utf8.encode(str);

Uint8List stringToUint8List(String str) =>
    Uint8List.fromList(str.codeUnits);

String uint8ListToString(Uint8List bytes) => String.fromCharCodes(bytes);

String removeNulls(String str) => str.replaceAll(RegExp(r'\x00'), '');
