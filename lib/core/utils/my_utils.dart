import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';

MyUtils gUtils = MyUtils();

class MyUtils {
  /// Show SnackBar with success color in green while given duration in ms
  void showSnackbar(BuildContext context, String msg, {int durationMs = 1000}) {
    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(milliseconds: durationMs),
        content: Text(msg),
        backgroundColor: c.primary,
        action: SnackBarAction(
          label: 'OK',
          textColor: c.primaryForeground,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Show SnackBar with error color in red while given duration in ms
  void showErrorSnackbar(
    BuildContext context,
    String msg, {
    int durationMs = 2000,
  }) {
    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(milliseconds: durationMs),
        content: Text(msg),
        backgroundColor: c.destructive,
        action: SnackBarAction(
          label: 'OK',
          textColor: c.foreground,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Show SnackBar with error color in red
  // void snackbarError(BuildContext context, String msg) {
  //   final snackBar = SnackBar(
  //     duration: const Duration(seconds: 2),
  //     content: Text(msg),
  //     backgroundColor: Colors.red,
  //     action: SnackBarAction(
  //       label: "Done",
  //       textColor: Colors.red[400],
  //       onPressed: () {},
  //     ),
  //   );
  //   ScaffoldMessenger.of(context).showSnackBar(snackBar);
  // }

  /// prints debugPrint to console
  void log(String msg) {
    if (kDebugMode) {
      debugPrint(msg);
    }
  }

  /// prints debugPrint to console with [ERROR] prefix
  void err(String msg) {
    if (kDebugMode) {
      debugPrint('[ERROR] $msg');
    }
  }

  String listIntToString(List<int> list) {
    return utf8.decode(list);
  }

  List<Uint8List> stringToUint8ListList(String str) {
    List<int> list = utf8.encode(str);
    return List.from(list);
  }

  Uint8List stringToUint8List(String str) {
    final List<int> codeUnits = str.codeUnits;
    final Uint8List unit8List = Uint8List.fromList(codeUnits);

    return unit8List;
  }

  String uint8ListToString(Uint8List uint8list) {
    return String.fromCharCodes(uint8list);
  }

  String removeNullFromString(String str) {
    return str.replaceAll(RegExp('\\0'), '');
  }

  List<int> stringToListInt(String str) {
    List<int> list = utf8.encode(str);
    return list;
  }
  // String getStrFromListInt(List<int> buf, int start, int len) {
  //   String str = String.fromCharCodes(buf, start);

  //   for (String e in buf) {
  //     str += e.toString();
  //   }
  // }

  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      dateTimeFormat: DateTimeFormat.none,
      colors: false,
      printEmojis: true,
    ),
    level: kDebugMode ? Level.trace : Level.warning,
  );
}
