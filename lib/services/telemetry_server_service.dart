import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'telemetry_server_service.g.dart';

/// Broadcasts tegrastats telemetry as a Server-Sent Events (SSE) stream on
/// `http://HOST:18765/telemetry`, using the wire format an external charting
/// tool expects (see `tegrastats_format.md`). Each sample is one frame:
///
///   `data: {"ts":..,"seq":..,"d":{..parsed metrics..}}` + a blank line
///
/// Bound to `0.0.0.0` so both a local tool (`localhost`) and a LAN tool
/// (`192.168.x.x`) can connect. Raw I/O only — the caller supplies the already
/// mapped `d` payload, keeping this free of any feature/UI imports.
class TelemetryServer {
  // 18765 sits above the Windows ephemeral range (1024–15000), so winnat can't
  // reserve it out from under us the way it does 8765. Change here if the
  // external tool needs a different port.
  static const int port = 18765;
  static const String path = '/telemetry';

  HttpServer? _server;
  final Set<HttpResponse> _clients = {};
  int _seq = 0;

  bool get isRunning => _server != null;
  int get clientCount => _clients.length;

  /// Starts the HTTP server if it isn't already running.
  Future<void> start() async {
    if (_server != null) return;
    HttpServer server;
    try {
      // Listen on dual-stack IPv4 (127.0.0.1) and IPv6 (::1 / localhost)
      server = await HttpServer.bind(
        InternetAddress.anyIPv6,
        port,
        v6Only: false,
        shared: true,
      );
    } catch (_) {
      try {
        server = await HttpServer.bind(
          InternetAddress.anyIPv4,
          port,
          shared: true,
        );
      } catch (_) {
        server = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          port,
          shared: true,
        );
      }
    }
    _server = server;
    server.listen(_handle, onError: (_) {});
  }

  void _handle(HttpRequest req) {
    final res = req.response;
    if (req.uri.path != path) {
      res.statusCode = HttpStatus.notFound;
      res.close();
      return;
    }
    res.headers
      ..set(HttpHeaders.contentTypeHeader, 'text/event-stream')
      ..set(HttpHeaders.cacheControlHeader, 'no-cache')
      ..set('Connection', 'keep-alive')
      ..set('Access-Control-Allow-Origin', '*');
    res.bufferOutput = false;
    _clients.add(res);
    // Drop the client from the fan-out set once it disconnects.
    res.done.whenComplete(() => _clients.remove(res)).ignore();
  }

  /// Wraps [payload] in a telemetry frame (adding `ts`/`seq`) and pushes it to
  /// every connected client. No-op when nobody is listening.
  void broadcast(Map<String, dynamic> payload) {
    if (_clients.isEmpty) return;
    final frame = 'data: ${jsonEncode({
          'ts': DateTime.now().millisecondsSinceEpoch,
          'seq': _seq++,
          'd': payload,
        })}\n\n';
    for (final res in _clients.toList()) {
      try {
        res.write(frame);
      } catch (_) {
        _clients.remove(res);
      }
    }
  }

  /// Closes all client connections and shuts the server down.
  Future<void> stop() async {
    for (final res in _clients.toList()) {
      try {
        await res.close();
      } catch (_) {}
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }

  void dispose() {
    stop();
  }
}

@Riverpod(keepAlive: true)
TelemetryServer telemetryServer(Ref ref) {
  final service = TelemetryServer();
  ref.onDispose(service.dispose);
  return service;
}
