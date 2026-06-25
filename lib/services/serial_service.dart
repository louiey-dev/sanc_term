import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'serial_service.g.dart';

class SerialService {
  // flutter_libserialport integration added in later step
  void dispose() {}
}

@Riverpod(keepAlive: true)
SerialService serialService(Ref ref) {
  final service = SerialService();
  ref.onDispose(service.dispose);
  return service;
}
