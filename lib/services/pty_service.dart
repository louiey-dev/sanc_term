import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pty_service.g.dart';

class PtyService {
  // flutter_pty integration added in later step
  void dispose() {}
}

@Riverpod(keepAlive: true)
PtyService ptyService(Ref ref) {
  final service = PtyService();
  ref.onDispose(service.dispose);
  return service;
}
