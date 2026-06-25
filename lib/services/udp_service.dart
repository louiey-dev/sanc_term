import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'udp_service.g.dart';

class UdpService {
  // UDP socket integration added in later step
  void dispose() {}
}

@Riverpod(keepAlive: true)
UdpService udpService(Ref ref) {
  final service = UdpService();
  ref.onDispose(service.dispose);
  return service;
}
