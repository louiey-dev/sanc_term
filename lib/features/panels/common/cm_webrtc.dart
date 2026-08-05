import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sanc_term_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/panel.dart';

/// State model for preserving WebRTC panel parameters across page transitions
class CmWebRtcParamsState {
  final String signalingUrl;
  final String roomId;
  final String peerId;
  final String stunServer;
  final String preferredCodec;
  final bool enableVideo;
  final bool enableAudio;
  final bool enableDataChannel;
  final bool isDirectWsMode;
  final bool isConnected;

  const CmWebRtcParamsState({
    this.signalingUrl = 'ws://192.168.1.100:8080/ws',
    this.roomId = 'room_01',
    this.peerId = 'embedded_board',
    this.stunServer = 'stun:stun.l.google.com:19302',
    this.preferredCodec = 'H264',
    this.enableVideo = true,
    this.enableAudio = true,
    this.enableDataChannel = true,
    this.isDirectWsMode = true,
    this.isConnected = false,
  });

  CmWebRtcParamsState copyWith({
    String? signalingUrl,
    String? roomId,
    String? peerId,
    String? stunServer,
    String? preferredCodec,
    bool? enableVideo,
    bool? enableAudio,
    bool? enableDataChannel,
    bool? isDirectWsMode,
    bool? isConnected,
  }) {
    return CmWebRtcParamsState(
      signalingUrl: signalingUrl ?? this.signalingUrl,
      roomId: roomId ?? this.roomId,
      peerId: peerId ?? this.peerId,
      stunServer: stunServer ?? this.stunServer,
      preferredCodec: preferredCodec ?? this.preferredCodec,
      enableVideo: enableVideo ?? this.enableVideo,
      enableAudio: enableAudio ?? this.enableAudio,
      enableDataChannel: enableDataChannel ?? this.enableDataChannel,
      isDirectWsMode: isDirectWsMode ?? this.isDirectWsMode,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

/// Riverpod provider for persisting WebRTC parameter values across panel navigation
final cmWebRtcParamsProvider = StateProvider<CmWebRtcParamsState>(
  (ref) => const CmWebRtcParamsState(),
);

class CmWebRtcPanel extends ConsumerStatefulWidget {
  const CmWebRtcPanel({super.key});

  @override
  ConsumerState<CmWebRtcPanel> createState() => _CmWebRtcPanelState();
}

class _CmWebRtcPanelState extends ConsumerState<CmWebRtcPanel> {
  late final TextEditingController _signalingUrl;
  late final TextEditingController _roomId;
  late final TextEditingController _peerId;
  late final TextEditingController _stunServer;
  late final TextEditingController _dataMessage;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(cmWebRtcParamsProvider);
    _signalingUrl = TextEditingController(text: saved.signalingUrl);
    _roomId = TextEditingController(text: saved.roomId);
    _peerId = TextEditingController(text: saved.peerId);
    _stunServer = TextEditingController(text: saved.stunServer);
    _dataMessage = TextEditingController(text: '');

    _signalingUrl.addListener(_saveParams);
    _roomId.addListener(_saveParams);
    _peerId.addListener(_saveParams);
    _stunServer.addListener(_saveParams);
  }

  void _saveParams() {
    ref.read(cmWebRtcParamsProvider.notifier).update(
          (s) => s.copyWith(
            signalingUrl: _signalingUrl.text,
            roomId: _roomId.text,
            peerId: _peerId.text,
            stunServer: _stunServer.text,
          ),
        );
  }

  @override
  void dispose() {
    _signalingUrl.dispose();
    _roomId.dispose();
    _peerId.dispose();
    _stunServer.dispose();
    _dataMessage.dispose();
    super.dispose();
  }

  void _toggleConnection() {
    final current = ref.read(cmWebRtcParamsProvider);
    ref.read(cmWebRtcParamsProvider.notifier).update(
          (s) => s.copyWith(isConnected: !current.isConnected),
        );

    final statusMsg = !current.isConnected
        ? 'Connecting WebRTC session to ${current.signalingUrl}...'
        : 'WebRTC session disconnected.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(statusMsg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final params = ref.watch(cmWebRtcParamsProvider);

    return MyPanel(
      icon: Icons.video_call,
      panelTitle: 'WebRTC Stream & Data',
      panelSubtitle:
          'Peer-to-peer WebRTC video streaming and DataChannel for libdatachannel embedded board',
      panelActions: [
        StatusBadge(
          label: params.isConnected ? 'CONNECTED' : 'DISCONNECTED',
          color: params.isConnected ? c.primary : c.muted,
        ),
      ],
      children: [
        // Card 1: Signaling & Connection Setup
        MyPanelBody(
          icon: Icons.settings_ethernet,
          title: 'Signaling & Peer Configuration',
          subtitle:
              'Set board WebSocket signaling URL, Room ID, and STUN/TURN parameters',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _field(
                    _signalingUrl,
                    'Signaling / Board WS URL',
                    width: 280,
                  ),
                  _field(
                    _roomId,
                    'Room ID',
                    width: 120,
                  ),
                  _field(
                    _peerId,
                    'Peer ID',
                    width: 140,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _field(
                    _stunServer,
                    'STUN Server',
                    width: 280,
                  ),
                  PanelActionButton(
                    icon: params.isConnected ? Icons.stop : Icons.play_arrow,
                    label: params.isConnected ? 'Disconnect' : 'Connect',
                    tooltipStr: params.isConnected
                        ? 'Disconnect WebRTC PeerConnection'
                        : 'Start WebRTC Signaling & Connection',
                    onPressed: _toggleConnection,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Card 2: Live Video Stream & Viewport
        MyPanelBody(
          icon: Icons.videocam,
          title: 'Live Camera Viewport',
          subtitle:
              'Real-time H.264/VP8 hardware-accelerated video rendering from embedded board',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilterChip(
                        label: Text('Video Track: ${params.enableVideo ? "ON" : "OFF"}'),
                        selected: params.enableVideo,
                        onSelected: (val) {
                          ref.read(cmWebRtcParamsProvider.notifier).update(
                                (s) => s.copyWith(enableVideo: val),
                              );
                        },
                      ),
                      FilterChip(
                        label: Text('Audio Track: ${params.enableAudio ? "ON" : "OFF"}'),
                        selected: params.enableAudio,
                        onSelected: (val) {
                          ref.read(cmWebRtcParamsProvider.notifier).update(
                                (s) => s.copyWith(enableAudio: val),
                              );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Codec: ',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                      DropdownButton<String>(
                        value: params.preferredCodec,
                        isDense: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'H264', child: Text('H.264')),
                          DropdownMenuItem(value: 'VP8', child: Text('VP8')),
                          DropdownMenuItem(value: 'VP9', child: Text('VP9')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(cmWebRtcParamsProvider.notifier).update(
                                  (s) => s.copyWith(preferredCodec: val),
                                );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border),
                ),
                child: Center(
                  child: params.isConnected
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam, size: 48, color: c.primary),
                            const SizedBox(height: 8),
                            const Text(
                              'WebRTC MediaStream Connected',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rendering live camera feed (${params.preferredCodec})',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.video_camera_front,
                                size: 48, color: Colors.white38),
                            SizedBox(height: 8),
                            Text(
                              'Camera Stream Disconnected',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),

        // Card 3: DataChannel & Telemetry
        MyPanelBody(
          icon: Icons.swap_calls,
          title: 'DataChannel & Control Overlay',
          subtitle:
              'Bi-directional SCTP data channel for command execution and telemetry',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable WebRTC DataChannel (PTY/Telemetry)'),
                subtitle: const Text('Exchanges raw commands and stats over SCTP'),
                value: params.enableDataChannel,
                onChanged: (val) {
                  ref.read(cmWebRtcParamsProvider.notifier).update(
                        (s) => s.copyWith(enableDataChannel: val),
                      );
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _field(
                    _dataMessage,
                    'Test message to libdatachannel',
                    width: 320,
                    enabled: params.isConnected && params.enableDataChannel,
                  ),
                  PanelActionButton(
                    icon: Icons.send,
                    label: 'Send',
                    tooltipStr: 'Send string message over WebRTC DataChannel',
                    onPressed: (params.isConnected && params.enableDataChannel)
                        ? () {
                            if (_dataMessage.text.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Sent over DataChannel: "${_dataMessage.text}"'),
                                ),
                              );
                              _dataMessage.clear();
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    double width = 160,
    bool numeric = false,
    bool enabled = true,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }
}
