import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mqtt_service.g.dart';

enum MqttServiceConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

enum MqttProtocolVersion { v31, v311 }

enum MqttQosLevel { atMostOnce, atLeastOnce, exactlyOnce }

enum MqttMessageDirection { incoming, outgoing }

class MqttConnectionOptions {
  const MqttConnectionOptions({
    required this.host,
    required this.port,
    required this.clientId,
    this.username = '',
    this.password = '',
    this.cleanSession = true,
    this.keepAliveSeconds = 20,
    this.connectTimeoutSeconds = 5,
    this.protocolVersion = MqttProtocolVersion.v311,
    this.autoReconnect = true,
    this.useTls = false,
    this.caCertificatePath = '',
    this.clientCertificatePath = '',
    this.privateKeyPath = '',
    this.privateKeyPassword = '',
  });

  final String host;
  final int port;
  final String clientId;
  final String username;
  final String password;
  final bool cleanSession;
  final int keepAliveSeconds;
  final int connectTimeoutSeconds;
  final MqttProtocolVersion protocolVersion;
  final bool autoReconnect;
  final bool useTls;
  final String caCertificatePath;
  final String clientCertificatePath;
  final String privateKeyPath;
  final String privateKeyPassword;
}

class MqttServiceMessage {
  const MqttServiceMessage({
    required this.direction,
    required this.topic,
    required this.payload,
    required this.qos,
    required this.retain,
    required this.time,
  });

  final MqttMessageDirection direction;
  final String topic;
  final List<int> payload;
  final MqttQosLevel qos;
  final bool retain;
  final DateTime time;
}

class MqttServiceDiagnostics {
  const MqttServiceDiagnostics({
    this.connectedAt,
    this.disconnectedAt,
    this.lastPingLatencyMs,
    this.averagePingLatencyMs,
    this.reconnectAttempts = 0,
    this.messagesSent = 0,
    this.messagesReceived = 0,
    this.bytesSent = 0,
    this.bytesReceived = 0,
  });

  final DateTime? connectedAt;
  final DateTime? disconnectedAt;
  final int? lastPingLatencyMs;
  final int? averagePingLatencyMs;
  final int reconnectAttempts;
  final int messagesSent;
  final int messagesReceived;
  final int bytesSent;
  final int bytesReceived;
}

class MqttConnectionException implements Exception {
  const MqttConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Owns one native TCP MQTT client and its stream subscriptions.
class MqttService {
  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;
  final _connectionEvents =
      StreamController<MqttServiceConnectionStatus>.broadcast();
  final _messages = StreamController<MqttServiceMessage>.broadcast();
  final _diagnostics = StreamController<MqttServiceDiagnostics>.broadcast();

  DateTime? _connectedAt;
  DateTime? _disconnectedAt;
  int _reconnectAttempts = 0;
  int _messagesSent = 0;
  int _messagesReceived = 0;
  int _bytesSent = 0;
  int _bytesReceived = 0;

  Stream<MqttServiceConnectionStatus> get connectionEvents =>
      _connectionEvents.stream;
  Stream<MqttServiceMessage> get messages => _messages.stream;
  Stream<MqttServiceDiagnostics> get diagnostics => _diagnostics.stream;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect(MqttConnectionOptions options) async {
    disconnect();
    _emitConnection(MqttServiceConnectionStatus.connecting);

    final client =
        MqttServerClient.withPort(options.host, options.clientId, options.port)
          ..keepAlivePeriod = options.keepAliveSeconds
          ..connectTimeoutPeriod = options.connectTimeoutSeconds * 1000
          ..autoReconnect = options.autoReconnect
          ..resubscribeOnAutoReconnect = true
          ..logging(on: false, logPayloads: false);

    if (options.protocolVersion == MqttProtocolVersion.v311) {
      client.setProtocolV311();
    } else {
      client.setProtocolV31();
    }

    var connectMessage = MqttConnectMessage().withClientIdentifier(
      options.clientId,
    );
    if (options.cleanSession) connectMessage = connectMessage.startClean();
    client.connectionMessage = connectMessage;

    if (options.useTls) {
      client
        ..secure = true
        ..securityContext = _buildSecurityContext(options);
    }

    client.onConnected = () => _handleConnected(client);
    client.onDisconnected = () => _handleDisconnected(client);
    client.onAutoReconnect = () {
      _reconnectAttempts++;
      _emitConnection(MqttServiceConnectionStatus.reconnecting);
      _emitDiagnostics();
    };
    client.onAutoReconnected = () => _handleConnected(client);
    client.pongCallback = _emitDiagnostics;

    _client = client;

    try {
      final status = await client.connect(
        options.username.isEmpty ? null : options.username,
        options.username.isEmpty ? null : options.password,
      );
      if (status?.state != MqttConnectionState.connected) {
        throw MqttConnectionException(_returnCodeMessage(status?.returnCode));
      }
      _attachUpdates(client);
    } catch (error) {
      if (identical(_client, client)) _client = null;
      client.disconnect();
      _emitConnection(MqttServiceConnectionStatus.disconnected);
      throw MqttConnectionException(_friendlyError(error));
    }
  }

  SecurityContext _buildSecurityContext(MqttConnectionOptions options) {
    final context = SecurityContext(withTrustedRoots: true);
    if (options.caCertificatePath.isNotEmpty) {
      context.setTrustedCertificates(options.caCertificatePath);
    }
    if (options.clientCertificatePath.isNotEmpty) {
      context.useCertificateChain(options.clientCertificatePath);
    }
    if (options.privateKeyPath.isNotEmpty) {
      context.usePrivateKey(
        options.privateKeyPath,
        password: options.privateKeyPassword,
      );
    }
    return context;
  }

  void _handleConnected(MqttServerClient client) {
    if (!identical(_client, client)) return;
    _connectedAt = DateTime.now();
    _emitConnection(MqttServiceConnectionStatus.connected);
    _attachUpdates(client);
    _emitDiagnostics();
  }

  void _handleDisconnected(MqttServerClient client) {
    if (!identical(_client, client)) return;
    _disconnectedAt = DateTime.now();
    if (!client.autoReconnect) _client = null;
    _emitConnection(MqttServiceConnectionStatus.disconnected);
    _emitDiagnostics();
  }

  void _attachUpdates(MqttServerClient client) {
    _updatesSub?.cancel();
    _updatesSub = client.updates?.listen((batch) {
      for (final received in batch) {
        final publish = received.payload as MqttPublishMessage;
        final bytes = List<int>.from(publish.payload.message);
        _messagesReceived++;
        _bytesReceived += bytes.length;
        _messages.add(
          MqttServiceMessage(
            direction: MqttMessageDirection.incoming,
            topic: received.topic,
            payload: bytes,
            qos: _fromPackageQos(publish.header?.qos),
            retain: publish.header?.retain ?? false,
            time: DateTime.now(),
          ),
        );
      }
      _emitDiagnostics();
    });
  }

  bool subscribe(String topic, MqttQosLevel qos) =>
      _requireConnected().subscribe(topic, _toPackageQos(qos)) != null;

  void unsubscribe(String topic) => _requireConnected().unsubscribe(topic);

  int publish(
    String topic,
    String payload,
    MqttQosLevel qos, {
    bool retain = false,
  }) {
    final client = _requireConnected();
    final builder = MqttClientPayloadBuilder()..addUTF8String(payload);
    final bytes = utf8.encode(payload);
    final id = client.publishMessage(
      topic,
      _toPackageQos(qos),
      builder.payload!,
      retain: retain,
    );
    _messagesSent++;
    _bytesSent += bytes.length;
    _messages.add(
      MqttServiceMessage(
        direction: MqttMessageDirection.outgoing,
        topic: topic,
        payload: bytes,
        qos: qos,
        retain: retain,
        time: DateTime.now(),
      ),
    );
    _emitDiagnostics();
    return id;
  }

  MqttServerClient _requireConnected() {
    final client = _client;
    if (client == null || !isConnected) {
      throw const MqttConnectionException('Connect to a broker first.');
    }
    return client;
  }

  void disconnect() {
    final client = _client;
    _client = null;
    _updatesSub?.cancel();
    _updatesSub = null;
    client?.disconnect();
    if (client != null) {
      _disconnectedAt = DateTime.now();
      _emitConnection(MqttServiceConnectionStatus.disconnected);
      _emitDiagnostics();
    }
  }

  void _emitConnection(MqttServiceConnectionStatus status) {
    if (!_connectionEvents.isClosed) _connectionEvents.add(status);
  }

  void _emitDiagnostics() {
    final client = _client;
    if (_diagnostics.isClosed) return;
    _diagnostics.add(
      MqttServiceDiagnostics(
        connectedAt: _connectedAt,
        disconnectedAt: _disconnectedAt,
        lastPingLatencyMs: client?.lastCycleLatency,
        averagePingLatencyMs: client?.averageCycleLatency,
        reconnectAttempts: _reconnectAttempts,
        messagesSent: _messagesSent,
        messagesReceived: _messagesReceived,
        bytesSent: _bytesSent,
        bytesReceived: _bytesReceived,
      ),
    );
  }

  MqttQos _toPackageQos(MqttQosLevel qos) => switch (qos) {
    MqttQosLevel.atMostOnce => MqttQos.atMostOnce,
    MqttQosLevel.atLeastOnce => MqttQos.atLeastOnce,
    MqttQosLevel.exactlyOnce => MqttQos.exactlyOnce,
  };

  MqttQosLevel _fromPackageQos(MqttQos? qos) => switch (qos) {
    MqttQos.atLeastOnce => MqttQosLevel.atLeastOnce,
    MqttQos.exactlyOnce => MqttQosLevel.exactlyOnce,
    _ => MqttQosLevel.atMostOnce,
  };

  String _returnCodeMessage(MqttConnectReturnCode? code) => switch (code) {
    MqttConnectReturnCode.badUsernameOrPassword =>
      'Authentication rejected: bad username or password.',
    MqttConnectReturnCode.notAuthorized =>
      'Authentication rejected: client is not authorized.',
    MqttConnectReturnCode.identifierRejected =>
      'The broker rejected the client ID.',
    MqttConnectReturnCode.unacceptedProtocolVersion =>
      'The broker does not support the selected MQTT protocol version.',
    MqttConnectReturnCode.brokerUnavailable =>
      'The MQTT broker is unavailable.',
    _ => 'The broker rejected the connection${code == null ? '' : ': $code'}.',
  };

  String _friendlyError(Object error) {
    if (error is MqttConnectionException) return error.message;
    if (error is SocketException) {
      final message = error.osError?.message ?? error.message;
      return 'Network connection failed: $message';
    }
    if (error is TimeoutException) return 'Connection timed out.';
    if (error is FileSystemException) {
      return 'TLS file error: ${error.message}';
    }
    return 'MQTT connection failed: $error';
  }

  void dispose() {
    disconnect();
    _connectionEvents.close();
    _messages.close();
    _diagnostics.close();
  }
}

@Riverpod(keepAlive: true)
MqttService mqttService(Ref ref) {
  final service = MqttService();
  ref.onDispose(service.dispose);
  return service;
}
