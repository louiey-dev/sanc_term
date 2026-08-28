import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/services/mqtt_service.dart';
import 'package:sanc_term/shared/widgets/common.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

part 'cm_mqtt.g.dart';

enum MqttConnectionStatus { disconnected, connecting, connected, reconnecting }

enum MqttPayloadView { text, json, hex }

class MqttState {
  const MqttState({
    this.status = MqttConnectionStatus.disconnected,
    this.brokerHost = 'localhost',
    this.brokerPort = 1883,
    this.clientId = 'sanc_term',
    this.username = '',
    this.cleanSession = true,
    this.keepAliveSeconds = 20,
    this.connectTimeoutSeconds = 5,
    this.protocolVersion = MqttProtocolVersion.v311,
    this.autoReconnect = true,
    this.useTls = false,
    this.caCertificatePath = '',
    this.clientCertificatePath = '',
    this.privateKeyPath = '',
    this.subscriptions = const {},
    this.messages = const [],
    this.diagnostics = const MqttServiceDiagnostics(),
    this.errorMessage,
  });

  final MqttConnectionStatus status;
  final String brokerHost;
  final int brokerPort;
  final String clientId;
  final String username;
  final bool cleanSession;
  final int keepAliveSeconds;
  final int connectTimeoutSeconds;
  final MqttProtocolVersion protocolVersion;
  final bool autoReconnect;
  final bool useTls;
  final String caCertificatePath;
  final String clientCertificatePath;
  final String privateKeyPath;
  final Map<String, MqttQosLevel> subscriptions;
  final List<MqttServiceMessage> messages;
  final MqttServiceDiagnostics diagnostics;
  final String? errorMessage;

  bool get isConnected => status == MqttConnectionStatus.connected;

  static const _unset = Object();

  MqttState copyWith({
    MqttConnectionStatus? status,
    String? brokerHost,
    int? brokerPort,
    String? clientId,
    String? username,
    bool? cleanSession,
    int? keepAliveSeconds,
    int? connectTimeoutSeconds,
    MqttProtocolVersion? protocolVersion,
    bool? autoReconnect,
    bool? useTls,
    String? caCertificatePath,
    String? clientCertificatePath,
    String? privateKeyPath,
    Map<String, MqttQosLevel>? subscriptions,
    List<MqttServiceMessage>? messages,
    MqttServiceDiagnostics? diagnostics,
    Object? errorMessage = _unset,
  }) {
    return MqttState(
      status: status ?? this.status,
      brokerHost: brokerHost ?? this.brokerHost,
      brokerPort: brokerPort ?? this.brokerPort,
      clientId: clientId ?? this.clientId,
      username: username ?? this.username,
      cleanSession: cleanSession ?? this.cleanSession,
      keepAliveSeconds: keepAliveSeconds ?? this.keepAliveSeconds,
      connectTimeoutSeconds:
          connectTimeoutSeconds ?? this.connectTimeoutSeconds,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      useTls: useTls ?? this.useTls,
      caCertificatePath: caCertificatePath ?? this.caCertificatePath,
      clientCertificatePath:
          clientCertificatePath ?? this.clientCertificatePath,
      privateKeyPath: privateKeyPath ?? this.privateKeyPath,
      subscriptions: subscriptions ?? this.subscriptions,
      messages: messages ?? this.messages,
      diagnostics: diagnostics ?? this.diagnostics,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

@Riverpod(keepAlive: true)
class MqttNotifier extends _$MqttNotifier {
  static const _maxMessages = 500;
  final _subscriptions = <StreamSubscription<dynamic>>[];

  MqttService get _mqtt => ref.read(mqttServiceProvider);

  @override
  MqttState build() {
    _subscriptions
      ..add(_mqtt.connectionEvents.listen(_handleConnection))
      ..add(_mqtt.messages.listen(_handleMessage))
      ..add(
        _mqtt.diagnostics.listen(
          (value) => state = state.copyWith(diagnostics: value),
        ),
      );
    ref.onDispose(() {
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
    });
    return _loadSettings();
  }

  MqttState _loadSettings() {
    try {
      if (!Hive.isBoxOpen('app_settings')) return const MqttState();
      final box = Hive.box<String>('app_settings');
      return MqttState(
        brokerHost: box.get('mqtt_host') ?? 'localhost',
        brokerPort: int.tryParse(box.get('mqtt_port') ?? '') ?? 1883,
        clientId: box.get('mqtt_client_id') ?? 'sanc_term',
        username: box.get('mqtt_username') ?? '',
        cleanSession: box.get('mqtt_clean_session') != 'false',
        keepAliveSeconds: int.tryParse(box.get('mqtt_keep_alive') ?? '') ?? 20,
        connectTimeoutSeconds: int.tryParse(box.get('mqtt_timeout') ?? '') ?? 5,
        protocolVersion: box.get('mqtt_protocol') == 'v31'
            ? MqttProtocolVersion.v31
            : MqttProtocolVersion.v311,
        autoReconnect: box.get('mqtt_auto_reconnect') != 'false',
        useTls: box.get('mqtt_tls') == 'true',
        caCertificatePath: box.get('mqtt_ca_path') ?? '',
        clientCertificatePath: box.get('mqtt_cert_path') ?? '',
        privateKeyPath: box.get('mqtt_key_path') ?? '',
      );
    } catch (_) {
      return const MqttState();
    }
  }

  void updateConnectionSettings({
    required String host,
    required int port,
    required String clientId,
    required String username,
    required bool cleanSession,
    required int keepAliveSeconds,
    required int connectTimeoutSeconds,
    required MqttProtocolVersion protocolVersion,
    required bool autoReconnect,
    required bool useTls,
    required String caCertificatePath,
    required String clientCertificatePath,
    required String privateKeyPath,
  }) {
    state = state.copyWith(
      brokerHost: host,
      brokerPort: port,
      clientId: clientId,
      username: username,
      cleanSession: cleanSession,
      keepAliveSeconds: keepAliveSeconds,
      connectTimeoutSeconds: connectTimeoutSeconds,
      protocolVersion: protocolVersion,
      autoReconnect: autoReconnect,
      useTls: useTls,
      caCertificatePath: caCertificatePath,
      clientCertificatePath: clientCertificatePath,
      privateKeyPath: privateKeyPath,
      errorMessage: null,
    );
    _saveSettings();
  }

  void _saveSettings() {
    try {
      if (!Hive.isBoxOpen('app_settings')) return;
      final box = Hive.box<String>('app_settings');
      box
        ..put('mqtt_host', state.brokerHost)
        ..put('mqtt_port', '${state.brokerPort}')
        ..put('mqtt_client_id', state.clientId)
        ..put('mqtt_username', state.username)
        ..put('mqtt_clean_session', '${state.cleanSession}')
        ..put('mqtt_keep_alive', '${state.keepAliveSeconds}')
        ..put('mqtt_timeout', '${state.connectTimeoutSeconds}')
        ..put('mqtt_protocol', state.protocolVersion.name)
        ..put('mqtt_auto_reconnect', '${state.autoReconnect}')
        ..put('mqtt_tls', '${state.useTls}')
        ..put('mqtt_ca_path', state.caCertificatePath)
        ..put('mqtt_cert_path', state.clientCertificatePath)
        ..put('mqtt_key_path', state.privateKeyPath);
    } catch (_) {}
  }

  Future<void> connect({String password = '', String keyPassword = ''}) async {
    if (state.status != MqttConnectionStatus.disconnected) return;
    state = state.copyWith(
      status: MqttConnectionStatus.connecting,
      errorMessage: null,
    );
    try {
      await _mqtt.connect(
        MqttConnectionOptions(
          host: state.brokerHost,
          port: state.brokerPort,
          clientId: state.clientId,
          username: state.username,
          password: password,
          cleanSession: state.cleanSession,
          keepAliveSeconds: state.keepAliveSeconds,
          connectTimeoutSeconds: state.connectTimeoutSeconds,
          protocolVersion: state.protocolVersion,
          autoReconnect: state.autoReconnect,
          useTls: state.useTls,
          caCertificatePath: state.caCertificatePath,
          clientCertificatePath: state.clientCertificatePath,
          privateKeyPath: state.privateKeyPath,
          privateKeyPassword: keyPassword,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        status: MqttConnectionStatus.disconnected,
        errorMessage: '$error',
      );
    }
  }

  void _handleConnection(MqttServiceConnectionStatus value) {
    final status = switch (value) {
      MqttServiceConnectionStatus.disconnected =>
        MqttConnectionStatus.disconnected,
      MqttServiceConnectionStatus.connecting => MqttConnectionStatus.connecting,
      MqttServiceConnectionStatus.connected => MqttConnectionStatus.connected,
      MqttServiceConnectionStatus.reconnecting =>
        MqttConnectionStatus.reconnecting,
    };
    state = state.copyWith(
      status: status,
      subscriptions: status == MqttConnectionStatus.disconnected
          ? const {}
          : state.subscriptions,
    );
  }

  void _handleMessage(MqttServiceMessage message) {
    final messages = [...state.messages, message];
    if (messages.length > _maxMessages) {
      messages.removeRange(0, messages.length - _maxMessages);
    }
    state = state.copyWith(messages: messages);
  }

  void disconnect() => _mqtt.disconnect();

  void subscribe(String topic, MqttQosLevel qos) {
    if (topic.isEmpty) return reportError('Subscription topic is required.');
    try {
      if (!_mqtt.subscribe(topic, qos)) {
        return reportError('The broker did not accept the subscription.');
      }
      state = state.copyWith(
        subscriptions: {...state.subscriptions, topic: qos},
        errorMessage: null,
      );
    } catch (error) {
      reportError('$error');
    }
  }

  void unsubscribe(String topic) {
    try {
      _mqtt.unsubscribe(topic);
      final subscriptions = {...state.subscriptions}..remove(topic);
      state = state.copyWith(subscriptions: subscriptions, errorMessage: null);
    } catch (error) {
      reportError('$error');
    }
  }

  void publish(
    String topic,
    String payload,
    MqttQosLevel qos, {
    required bool retain,
  }) {
    if (topic.isEmpty) return reportError('Publish topic is required.');
    try {
      _mqtt.publish(topic, payload, qos, retain: retain);
      state = state.copyWith(errorMessage: null);
    } catch (error) {
      reportError('$error');
    }
  }

  void clearMessages() => state = state.copyWith(messages: const []);
  void clearError() => state = state.copyWith(errorMessage: null);
  void reportError(String message) =>
      state = state.copyWith(errorMessage: message);
}

class CmMqttPanel extends ConsumerStatefulWidget {
  const CmMqttPanel({super.key});

  @override
  ConsumerState<CmMqttPanel> createState() => _CmMqttPanelState();
}

class _CmMqttPanelState extends ConsumerState<CmMqttPanel> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _clientId;
  late final TextEditingController _username;
  final _password = TextEditingController();
  late final TextEditingController _keepAlive;
  late final TextEditingController _timeout;
  late final TextEditingController _caPath;
  late final TextEditingController _certPath;
  late final TextEditingController _keyPath;
  final _keyPassword = TextEditingController();
  final _subscribeTopic = TextEditingController(text: '#');
  final _publishTopic = TextEditingController();
  final _payload = TextEditingController();
  final _search = TextEditingController();

  late bool _cleanSession;
  late bool _autoReconnect;
  late bool _useTls;
  late MqttProtocolVersion _protocol;
  MqttQosLevel _subscribeQos = MqttQosLevel.atMostOnce;
  MqttQosLevel _publishQos = MqttQosLevel.atMostOnce;
  bool _retain = false;
  bool _hidePassword = true;
  bool _hideKeyPassword = true;
  bool _autoScroll = true;
  MqttPayloadView _payloadView = MqttPayloadView.text;
  MqttMessageDirection? _directionFilter;

  @override
  void initState() {
    super.initState();
    final state = ref.read(mqttNotifierProvider);
    _host = TextEditingController(text: state.brokerHost);
    _port = TextEditingController(text: '${state.brokerPort}');
    _clientId = TextEditingController(text: state.clientId);
    _username = TextEditingController(text: state.username);
    _keepAlive = TextEditingController(text: '${state.keepAliveSeconds}');
    _timeout = TextEditingController(text: '${state.connectTimeoutSeconds}');
    _caPath = TextEditingController(text: state.caCertificatePath);
    _certPath = TextEditingController(text: state.clientCertificatePath);
    _keyPath = TextEditingController(text: state.privateKeyPath);
    _cleanSession = state.cleanSession;
    _autoReconnect = state.autoReconnect;
    _useTls = state.useTls;
    _protocol = state.protocolVersion;
  }

  @override
  void dispose() {
    for (final controller in [
      _host,
      _port,
      _clientId,
      _username,
      _password,
      _keepAlive,
      _timeout,
      _caPath,
      _certPath,
      _keyPath,
      _keyPassword,
      _subscribeTopic,
      _publishTopic,
      _payload,
      _search,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _connect() {
    final notifier = ref.read(mqttNotifierProvider.notifier);
    final host = _host.text.trim();
    final port = int.tryParse(_port.text.trim());
    final keepAlive = int.tryParse(_keepAlive.text.trim());
    final timeout = int.tryParse(_timeout.text.trim());
    if (host.isEmpty) return notifier.reportError('Broker host is required.');
    if (port == null || port < 1 || port > 65535) {
      return notifier.reportError('Broker port must be between 1 and 65535.');
    }
    if (_clientId.text.trim().isEmpty) {
      return notifier.reportError('Client ID is required.');
    }
    if (keepAlive == null || keepAlive < 0) {
      return notifier.reportError('Keep alive must be zero or greater.');
    }
    if (timeout == null || timeout < 1) {
      return notifier.reportError(
        'Connection timeout must be at least 1 second.',
      );
    }
    notifier
      ..updateConnectionSettings(
        host: host,
        port: port,
        clientId: _clientId.text.trim(),
        username: _username.text.trim(),
        cleanSession: _cleanSession,
        keepAliveSeconds: keepAlive,
        connectTimeoutSeconds: timeout,
        protocolVersion: _protocol,
        autoReconnect: _autoReconnect,
        useTls: _useTls,
        caCertificatePath: _caPath.text.trim(),
        clientCertificatePath: _certPath.text.trim(),
        privateKeyPath: _keyPath.text.trim(),
      )
      ..connect(password: _password.text, keyPassword: _keyPassword.text);
  }

  Future<void> _pickFile(TextEditingController controller) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pem', 'crt', 'cer', 'key'],
    );
    final path = result?.files.single.path;
    if (path != null && mounted) setState(() => controller.text = path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mqttNotifierProvider);
    final notifier = ref.read(mqttNotifierProvider.notifier);
    final colors = context.colors;
    final disconnected = state.status == MqttConnectionStatus.disconnected;

    return MyPanel(
      icon: Icons.cloud_outlined,
      panelTitle: 'MQTT',
      panelSubtitle: 'Connect, subscribe, publish, and inspect MQTT traffic',
      panelActions: [
        StatusBadge(
          label: state.status.name.toUpperCase(),
          color: switch (state.status) {
            MqttConnectionStatus.disconnected => colors.muted,
            MqttConnectionStatus.connecting ||
            MqttConnectionStatus.reconnecting => colors.warning,
            MqttConnectionStatus.connected => colors.success,
          },
        ),
      ],
      children: [
        _brokerSection(state, notifier, disconnected),
        _subscriptionsSection(state, notifier),
        _publishSection(state, notifier),
        _trafficSection(state, notifier),
        _diagnosticsSection(state),
        if (state.errorMessage != null) _errorSection(state, notifier, colors),
      ],
    );
  }

  Widget _brokerSection(
    MqttState state,
    MqttNotifier notifier,
    bool disconnected,
  ) {
    return MyPanelBody(
      icon: Icons.dns_outlined,
      title: 'Broker',
      subtitle: 'TCP endpoint and connection credentials',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _field(_host, 'Host', 210, enabled: disconnected),
              _field(_port, 'Port', 90, numeric: true, enabled: disconnected),
              _field(_clientId, 'Client ID', 180, enabled: disconnected),
              PanelActionButton(
                icon: Icons.link,
                label: 'Connect',
                tooltipStr: 'Connect to the MQTT broker',
                onPressed: disconnected ? _connect : null,
              ),
              PanelActionButton(
                icon: Icons.link_off,
                label: 'Disconnect',
                tooltipStr: 'Disconnect from the MQTT broker',
                onPressed: state.isConnected ? notifier.disconnect : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Advanced connection settings'),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _field(_username, 'Username', 180, enabled: disconnected),
                  _passwordField(
                    _password,
                    'Password',
                    _hidePassword,
                    () => setState(() => _hidePassword = !_hidePassword),
                    disconnected,
                  ),
                  _field(
                    _keepAlive,
                    'Keep alive (s)',
                    130,
                    numeric: true,
                    enabled: disconnected,
                  ),
                  _field(
                    _timeout,
                    'Timeout (s)',
                    120,
                    numeric: true,
                    enabled: disconnected,
                  ),
                  _protocolDropdown(disconnected),
                ],
              ),
              Wrap(
                spacing: 16,
                children: [
                  _check(
                    'Clean session',
                    _cleanSession,
                    disconnected,
                    (v) => setState(() => _cleanSession = v),
                  ),
                  _check(
                    'Auto reconnect',
                    _autoReconnect,
                    disconnected,
                    (v) => setState(() => _autoReconnect = v),
                  ),
                  _check(
                    'TLS',
                    _useTls,
                    disconnected,
                    (v) => setState(() {
                      _useTls = v;
                      if (v && _port.text == '1883') _port.text = '8883';
                    }),
                  ),
                ],
              ),
              if (_useTls) ...[
                _fileField(_caPath, 'CA certificate', disconnected),
                _fileField(_certPath, 'Client certificate', disconnected),
                _fileField(_keyPath, 'Private key', disconnected),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _passwordField(
                    _keyPassword,
                    'Private-key password',
                    _hideKeyPassword,
                    () => setState(() => _hideKeyPassword = !_hideKeyPassword),
                    disconnected,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _subscriptionsSection(MqttState state, MqttNotifier notifier) {
    return MyPanelBody(
      icon: Icons.call_received,
      title: 'Subscriptions',
      subtitle: '${state.subscriptions.length} active topic filters',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _field(
                _subscribeTopic,
                'Topic filter',
                280,
                enabled: state.isConnected,
              ),
              _qosDropdown(
                _subscribeQos,
                state.isConnected,
                (value) => setState(() => _subscribeQos = value),
              ),
              PanelActionButton(
                icon: Icons.add,
                label: 'Subscribe',
                tooltipStr: 'Subscribe to this topic filter',
                onPressed: state.isConnected
                    ? () => notifier.subscribe(
                        _subscribeTopic.text.trim(),
                        _subscribeQos,
                      )
                    : null,
              ),
            ],
          ),
          if (state.subscriptions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: state.subscriptions.entries
                  .map(
                    (entry) => InputChip(
                      label: Text('${entry.key} · ${_qosLabel(entry.value)}'),
                      onDeleted: state.isConnected
                          ? () => notifier.unsubscribe(entry.key)
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _publishSection(MqttState state, MqttNotifier notifier) {
    return MyPanelBody(
      icon: Icons.send,
      title: 'Publish',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _field(_publishTopic, 'Topic', 280, enabled: state.isConnected),
              _qosDropdown(
                _publishQos,
                state.isConnected,
                (value) => setState(() => _publishQos = value),
              ),
              _check(
                'Retain',
                _retain,
                state.isConnected,
                (v) => setState(() => _retain = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _payload,
            enabled: state.isConnected,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Payload',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          PanelActionButton(
            icon: Icons.send,
            label: 'Publish',
            tooltipStr: 'Publish this payload',
            onPressed: state.isConnected
                ? () => notifier.publish(
                    _publishTopic.text.trim(),
                    _payload.text,
                    _publishQos,
                    retain: _retain,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _trafficSection(MqttState state, MqttNotifier notifier) {
    final query = _search.text.trim().toLowerCase();
    final filtered = state.messages.where((message) {
      if (_directionFilter != null && message.direction != _directionFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final payload = utf8.decode(message.payload, allowMalformed: true);
      return message.topic.toLowerCase().contains(query) ||
          payload.toLowerCase().contains(query);
    }).toList();

    return MyPanelBody(
      icon: Icons.receipt_long,
      title: 'Traffic',
      subtitle: '${filtered.length} of ${state.messages.length} messages',
      trailing: PanelActionButton(
        icon: Icons.clear_all,
        label: 'Clear',
        tooltipStr: 'Clear the traffic log',
        onPressed: notifier.clearMessages,
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search topic or payload',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              DropdownButton<MqttMessageDirection?>(
                value: _directionFilter,
                hint: const Text('All directions'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All directions')),
                  DropdownMenuItem(
                    value: MqttMessageDirection.incoming,
                    child: Text('Incoming'),
                  ),
                  DropdownMenuItem(
                    value: MqttMessageDirection.outgoing,
                    child: Text('Outgoing'),
                  ),
                ],
                onChanged: (value) => setState(() => _directionFilter = value),
              ),
              DropdownButton<MqttPayloadView>(
                value: _payloadView,
                items: MqttPayloadView.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _payloadView = value ?? _payloadView),
              ),
              _check(
                'Auto-scroll',
                _autoScroll,
                true,
                (v) => setState(() => _autoScroll = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TrafficLog(
            messages: filtered,
            payloadView: _payloadView,
            newestFirst: _autoScroll,
          ),
        ],
      ),
    );
  }

  Widget _diagnosticsSection(MqttState state) {
    final d = state.diagnostics;
    return MyPanelBody(
      icon: Icons.monitor_heart_outlined,
      title: 'Diagnostics',
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          _metric('Connected', _formatTime(d.connectedAt)),
          _metric('Disconnected', _formatTime(d.disconnectedAt)),
          _metric('Last ping', '${d.lastPingLatencyMs ?? '-'} ms'),
          _metric('Average ping', '${d.averagePingLatencyMs ?? '-'} ms'),
          _metric('Reconnects', '${d.reconnectAttempts}'),
          _metric('Subscriptions', '${state.subscriptions.length}'),
          _metric('Messages TX/RX', '${d.messagesSent}/${d.messagesReceived}'),
          _metric('Bytes TX/RX', '${d.bytesSent}/${d.bytesReceived}'),
        ],
      ),
    );
  }

  Widget _errorSection(MqttState state, MqttNotifier notifier, AppColors c) {
    return MyPanelBody(
      icon: Icons.error_outline,
      title: 'Last Error',
      trailing: PanelActionButton(
        icon: Icons.clear,
        label: 'Clear',
        tooltipStr: 'Clear the last error',
        onPressed: notifier.clearError,
      ),
      child: SelectableText(
        state.errorMessage!,
        style: TextStyle(color: c.destructive),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    double width, {
    required bool enabled,
    bool numeric = false,
  }) {
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        controller: controller,
        enabled: enabled,
        onSubmitted: (_) {
          if (enabled && identical(controller, _host)) _connect();
        },
        keyboardType: numeric ? TextInputType.number : null,
        inputFormatters: numeric
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    String label,
    bool obscure,
    VoidCallback toggle,
    bool enabled,
  ) {
    return SizedBox(
      width: 220,
      height: 40,
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: IconButton(
            onPressed: toggle,
            icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          ),
        ),
      ),
    );
  }

  Widget _fileField(
    TextEditingController controller,
    String label,
    bool enabled,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _field(controller, label, double.infinity, enabled: enabled),
          ),
          const SizedBox(width: 8),
          PanelActionButton(
            icon: Icons.folder_open,
            label: 'Browse',
            tooltipStr: 'Select $label',
            onPressed: enabled ? () => _pickFile(controller) : null,
          ),
        ],
      ),
    );
  }

  Widget _protocolDropdown(bool enabled) => SizedBox(
    width: 130,
    child: DropdownButtonFormField<MqttProtocolVersion>(
      initialValue: _protocol,
      decoration: const InputDecoration(
        labelText: 'Protocol',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(
          value: MqttProtocolVersion.v31,
          child: Text('MQTT 3.1'),
        ),
        DropdownMenuItem(
          value: MqttProtocolVersion.v311,
          child: Text('MQTT 3.1.1'),
        ),
      ],
      onChanged: enabled
          ? (value) => setState(() => _protocol = value ?? _protocol)
          : null,
    ),
  );

  Widget _qosDropdown(
    MqttQosLevel value,
    bool enabled,
    ValueChanged<MqttQosLevel> onChanged,
  ) => SizedBox(
    width: 104,
    child: DropdownButtonFormField<MqttQosLevel>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down, size: 18),
      decoration: const InputDecoration(
        labelText: 'QoS',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      items: MqttQosLevel.values
          .map(
            (qos) => DropdownMenuItem(value: qos, child: Text(_qosLabel(qos))),
          )
          .toList(),
      selectedItemBuilder: (_) => const [
        Align(alignment: Alignment.centerLeft, child: Text('0')),
        Align(alignment: Alignment.centerLeft, child: Text('1')),
        Align(alignment: Alignment.centerLeft, child: Text('2')),
      ],
      onChanged: enabled
          ? (next) {
              if (next != null) onChanged(next);
            }
          : null,
    ),
  );

  Widget _check(
    String label,
    bool value,
    bool enabled,
    ValueChanged<bool> changed,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Checkbox(
        value: value,
        onChanged: enabled ? (next) => changed(next ?? value) : null,
      ),
      Text(label),
    ],
  );

  Widget _metric(String label, String value) => SizedBox(
    width: 130,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.colors.muted)),
        SelectableText(value),
      ],
    ),
  );

  String _formatTime(DateTime? value) => value == null
      ? '-'
      : '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';
}

class _TrafficLog extends StatelessWidget {
  const _TrafficLog({
    required this.messages,
    required this.payloadView,
    required this.newestFirst,
  });

  final List<MqttServiceMessage> messages;
  final MqttPayloadView payloadView;
  final bool newestFirst;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (messages.isEmpty) {
      return Text('No MQTT traffic.', style: TextStyle(color: c.muted));
    }
    final visible = newestFirst ? messages.reversed.toList() : messages;
    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: visible.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: c.border),
        itemBuilder: (_, index) {
          final message = visible[index];
          final incoming = message.direction == MqttMessageDirection.incoming;
          final color = incoming ? c.foreground : c.primary;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  incoming ? Icons.south_west : Icons.north_east,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        '${_time(message.time)}  ${incoming ? 'RX' : 'TX'}  ${message.topic}  ${_qosLabel(message.qos)}${message.retain ? '  RETAIN' : ''}',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Consolas',
                          color: c.muted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      SelectableText(
                        _formatPayload(message.payload, payloadView),
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Consolas',
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy topic and payload',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Clipboard.setData(
                    ClipboardData(
                      text:
                          '${message.topic}\n${utf8.decode(message.payload, allowMalformed: true)}',
                    ),
                  ),
                  icon: const Icon(Icons.copy, size: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _formatPayload(List<int> bytes, MqttPayloadView view) {
    final text = utf8.decode(bytes, allowMalformed: true);
    return switch (view) {
      MqttPayloadView.text => text,
      MqttPayloadView.hex =>
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' '),
      MqttPayloadView.json => _prettyJson(text),
    };
  }

  static String _prettyJson(String text) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(text));
    } catch (_) {
      return text;
    }
  }

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';
}

String _qosLabel(MqttQosLevel qos) => switch (qos) {
  MqttQosLevel.atMostOnce => 'QoS 0',
  MqttQosLevel.atLeastOnce => 'QoS 1',
  MqttQosLevel.exactlyOnce => 'QoS 2',
};
