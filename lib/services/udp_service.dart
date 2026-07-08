import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'udp_service.g.dart';

/// One received UDP datagram: the sender's address/port plus the raw bytes.
class UdpDatagram {
  const UdpDatagram({
    required this.address,
    required this.port,
    required this.data,
  });

  final String address;
  final int port;
  final List<int> data;

  String get peer => '$address:$port';
}

/// Raw UDP socket I/O — bind a local port to receive datagrams, and send to a
/// remote host:port. No Flutter widgets and no feature imports; the provider
/// layer decides when to bind and folds [incoming] into UI state.
///
/// A single [RawDatagramSocket] backs both directions: binding to receive also
/// serves as the send socket, and send lazily binds an ephemeral socket when
/// nothing is listening yet.
class UdpService {
  RawDatagramSocket? _socket;
  final _incoming = StreamController<UdpDatagram>.broadcast();

  /// Datagrams arriving on the bound port.
  Stream<UdpDatagram> get incoming => _incoming.stream;

  bool get isBound => _socket != null;

  /// The local port currently bound, or null when not listening.
  int? get boundPort => _socket?.port;

  /// Binds [port] on all IPv4 interfaces and starts delivering datagrams to
  /// [incoming]. Replaces any existing socket. Pass 0 for an ephemeral port.
  Future<void> bind(int port) async {
    close();
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _socket = socket;
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = socket.receive();
      if (dg == null) return;
      _incoming.add(
        UdpDatagram(address: dg.address.address, port: dg.port, data: dg.data),
      );
    });
  }

  /// Sends [data] to [host]:[port]. Binds an ephemeral socket first if nothing
  /// is listening. [host] may be an IP literal or a hostname (resolved via DNS).
  /// Returns the number of bytes written (0 if the socket would block).
  Future<int> send(String host, int port, List<int> data) async {
    _socket ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final address =
        InternetAddress.tryParse(host) ?? (await InternetAddress.lookup(host)).first;
    return _socket!.send(data, address, port);
  }

  /// Closes the socket, stopping reception. Send will re-bind on next use.
  void close() {
    _socket?.close();
    _socket = null;
  }

  void dispose() {
    close();
    _incoming.close();
  }
}

@Riverpod(keepAlive: true)
UdpService udpService(Ref ref) {
  final service = UdpService();
  ref.onDispose(service.dispose);
  return service;
}
