import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final log = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    dateTimeFormat: DateTimeFormat.none,
    colors: false,
    printEmojis: true,
  ),
  level: kDebugMode ? Level.trace : Level.warning,
);
