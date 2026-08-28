import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hive_ce/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/sanc_term_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/panel.dart';

/// Signaling modes supported by the panel
enum WebRtcSignalingMode { manualSdp, webSocket, webBrowser }

/// WebRTC Binary Envelope Protocol Command Identifiers (Option A Header Framing)
const int kMsgTypeRawByteArray = 0x01;
const int kMsgTypeFileStart = 0x02;
const int kMsgTypeFileChunk = 0x03;
const int kMsgTypeFileEnd = 0x04;

/// Load WebRTC parameters from persistent Hive app_settings box
CmWebRtcParamsState _loadWebRtcParamsFromHive() {
  try {
    if (Hive.isBoxOpen('app_settings')) {
      final box = Hive.box<String>('app_settings');
      final modeStr = box.get('webrtc_signaling_mode');
      final mode = modeStr == 'webSocket'
          ? WebRtcSignalingMode.webSocket
          : (modeStr == 'webBrowser' || modeStr == 'embeddedBrowser'
                ? WebRtcSignalingMode.webBrowser
                : WebRtcSignalingMode.manualSdp);

      final vhStr = box.get('webrtc_viewport_height');
      final viewportHeight = vhStr != null
          ? double.tryParse(vhStr) ?? 360.0
          : 360.0;

      final binaryEnv = box.get('webrtc_binary_envelope') != 'false';

      return CmWebRtcParamsState(
        mode: mode,
        signalingUrl:
            box.get('webrtc_signaling_url') ?? 'ws://192.168.1.100:8080/ws',
        webUrl: box.get('webrtc_web_url') ?? 'http://192.168.1.7:8080/',
        roomId: box.get('webrtc_room_id') ?? 'room_01',
        peerId: box.get('webrtc_peer_id') ?? 'embedded_board',
        stunServer:
            box.get('webrtc_stun_server') ?? 'stun:stun.l.google.com:19302',
        preferredCodec: box.get('webrtc_preferred_codec') ?? 'H264',
        viewportHeight: viewportHeight,
        useBinaryHeaderEnvelope: binaryEnv,
      );
    }
  } catch (_) {}
  return const CmWebRtcParamsState();
}

/// Save WebRTC parameters into persistent Hive app_settings box
void _saveWebRtcParamsToHive(CmWebRtcParamsState state) {
  try {
    if (Hive.isBoxOpen('app_settings')) {
      final box = Hive.box<String>('app_settings');
      box.put('webrtc_signaling_mode', state.mode.name);
      box.put('webrtc_signaling_url', state.signalingUrl);
      box.put('webrtc_web_url', state.webUrl);
      box.put('webrtc_room_id', state.roomId);
      box.put('webrtc_peer_id', state.peerId);
      box.put('webrtc_stun_server', state.stunServer);
      box.put('webrtc_preferred_codec', state.preferredCodec);
      box.put('webrtc_viewport_height', state.viewportHeight.toString());
      box.put(
        'webrtc_binary_envelope',
        state.useBinaryHeaderEnvelope.toString(),
      );
    }
  } catch (_) {}
}

/// State model for preserving WebRTC panel parameters across page transitions
class CmWebRtcParamsState {
  final WebRtcSignalingMode mode;
  final String signalingUrl;
  final String webUrl;
  final String roomId;
  final String peerId;
  final String stunServer;
  final String preferredCodec;
  final bool enableVideo;
  final bool enableAudio;
  final bool enableDataChannel;
  final bool isConnected;
  final String remoteSdpOffer;
  final String localSdpAnswer;
  final String localIceCandidates;
  final String remoteIceCandidates;
  final double viewportHeight;
  final bool useBinaryHeaderEnvelope;

  const CmWebRtcParamsState({
    this.mode = WebRtcSignalingMode.manualSdp,
    this.signalingUrl = 'ws://192.168.1.100:8080/ws',
    this.webUrl = 'http://192.168.1.7:8080/',
    this.roomId = 'room_01',
    this.peerId = 'embedded_board',
    this.stunServer = 'stun:stun.l.google.com:19302',
    this.preferredCodec = 'H264',
    this.enableVideo = true,
    this.enableAudio = true,
    this.enableDataChannel = true,
    this.isConnected = false,
    this.remoteSdpOffer = '',
    this.localSdpAnswer = '',
    this.localIceCandidates = '',
    this.remoteIceCandidates = '',
    this.viewportHeight = 360.0,
    this.useBinaryHeaderEnvelope = true,
  });

  CmWebRtcParamsState copyWith({
    WebRtcSignalingMode? mode,
    String? signalingUrl,
    String? webUrl,
    String? roomId,
    String? peerId,
    String? stunServer,
    String? preferredCodec,
    bool? enableVideo,
    bool? enableAudio,
    bool? enableDataChannel,
    bool? isConnected,
    String? remoteSdpOffer,
    String? localSdpAnswer,
    String? localIceCandidates,
    String? remoteIceCandidates,
    double? viewportHeight,
    bool? useBinaryHeaderEnvelope,
  }) {
    return CmWebRtcParamsState(
      mode: mode ?? this.mode,
      signalingUrl: signalingUrl ?? this.signalingUrl,
      webUrl: webUrl ?? this.webUrl,
      roomId: roomId ?? this.roomId,
      peerId: peerId ?? this.peerId,
      stunServer: stunServer ?? this.stunServer,
      preferredCodec: preferredCodec ?? this.preferredCodec,
      enableVideo: enableVideo ?? this.enableVideo,
      enableAudio: enableAudio ?? this.enableAudio,
      enableDataChannel: enableDataChannel ?? this.enableDataChannel,
      isConnected: isConnected ?? this.isConnected,
      remoteSdpOffer: remoteSdpOffer ?? this.remoteSdpOffer,
      localSdpAnswer: localSdpAnswer ?? this.localSdpAnswer,
      localIceCandidates: localIceCandidates ?? this.localIceCandidates,
      remoteIceCandidates: remoteIceCandidates ?? this.remoteIceCandidates,
      viewportHeight: viewportHeight ?? this.viewportHeight,
      useBinaryHeaderEnvelope:
          useBinaryHeaderEnvelope ?? this.useBinaryHeaderEnvelope,
    );
  }
}

/// Riverpod provider for persisting WebRTC parameter values across panel navigation and app restarts
final cmWebRtcParamsProvider = StateProvider<CmWebRtcParamsState>(
  (ref) => _loadWebRtcParamsFromHive(),
);

/// Long-lived WebRTC resources that must survive routed panel replacement.
class CmWebRtcSession {
  RTCPeerConnection? peerConnection;
  RTCDataChannel? dataChannel;
  MediaStream? remoteStream;
  final List<RTCDataChannel> channels = [];

  Future<void> close() async {
    final peer = peerConnection;
    peerConnection = null;
    dataChannel = null;
    remoteStream = null;
    channels.clear();
    await peer?.close();
    await peer?.dispose();
  }
}

final cmWebRtcSessionProvider = Provider<CmWebRtcSession>((ref) {
  final session = CmWebRtcSession();
  ref.onDispose(session.close);
  return session;
});

class CmWebRtcPanel extends ConsumerStatefulWidget {
  const CmWebRtcPanel({super.key});

  @override
  ConsumerState<CmWebRtcPanel> createState() => _CmWebRtcPanelState();
}

class _CmWebRtcPanelState extends ConsumerState<CmWebRtcPanel> {
  late final CmWebRtcSession _session;
  late final TextEditingController _signalingUrl;
  late final TextEditingController _webUrlCtrl;
  late final TextEditingController _roomId;
  late final TextEditingController _peerId;
  late final TextEditingController _stunServer;
  late final TextEditingController _remoteSdpCtrl;
  late final TextEditingController _remoteCandidatesCtrl;
  late final TextEditingController _localAnswerCtrl;
  late final TextEditingController _localCandidatesCtrl;
  late final TextEditingController _dataMessage;
  late final TextEditingController _byteInputCtrl;
  late final TextEditingController _fileInfoCtrl;

  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isSendingFile = false;
  double _fileSendProgress = 0.0;

  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  final List<String> _logs = [];

  Timer? _statsTimer;
  int _prevAudioPackets = 0;
  int _prevVideoPackets = 0;
  int _prevAudioBytes = 0;
  int _prevVideoBytes = 0;
  bool _hasRecordedInitialStats = false;

  @override
  void initState() {
    super.initState();
    _session = ref.read(cmWebRtcSessionProvider);
    _peerConnection = _session.peerConnection;
    _dataChannel = _session.dataChannel;
    _allChannels.addAll(_session.channels);
    final saved = ref.read(cmWebRtcParamsProvider);
    _signalingUrl = TextEditingController(text: saved.signalingUrl);
    _webUrlCtrl = TextEditingController(text: saved.webUrl);
    _roomId = TextEditingController(text: saved.roomId);
    _peerId = TextEditingController(text: saved.peerId);
    _stunServer = TextEditingController(text: saved.stunServer);
    _remoteSdpCtrl = TextEditingController(text: saved.remoteSdpOffer);
    _remoteCandidatesCtrl = TextEditingController(
      text: saved.remoteIceCandidates,
    );
    _localAnswerCtrl = TextEditingController(text: saved.localSdpAnswer);
    _localCandidatesCtrl = TextEditingController(
      text: saved.localIceCandidates,
    );
    _dataMessage = TextEditingController(text: '');
    _byteInputCtrl = TextEditingController(text: '01 02 03 04 AA BB CC DD');
    _fileInfoCtrl = TextEditingController(text: '');

    _signalingUrl.addListener(_saveParams);
    _webUrlCtrl.addListener(_saveParams);
    _roomId.addListener(_saveParams);
    _peerId.addListener(_saveParams);
    _stunServer.addListener(_saveParams);

    _initVideoRenderer();
  }

  void _saveParams() {
    final newState = ref
        .read(cmWebRtcParamsProvider.notifier)
        .update(
          (s) => s.copyWith(
            signalingUrl: _signalingUrl.text,
            webUrl: _webUrlCtrl.text,
            roomId: _roomId.text,
            peerId: _peerId.text,
            stunServer: _stunServer.text,
          ),
        );
    _saveWebRtcParamsToHive(newState);
  }

  Future<void> _openExternalBrowser() async {
    try {
      final url = _webUrlCtrl.text.trim();
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          _addLog('Opened external web browser for: $url');
          return;
        }
      }
      _addLog('Cannot launch web browser for: $url');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot launch web browser for: $url')),
      );
    } catch (e) {
      _addLog('Error opening web browser: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening web browser: $e')));
    }
  }

  Future<void> _initVideoRenderer() async {
    await _remoteRenderer.initialize();
    _remoteRenderer.srcObject = _session.remoteStream;
    if (_peerConnection != null) {
      _reattachSessionCallbacks();
      _startPacketStatsLogging();
      _startStatePolling();
    }
    if (mounted) setState(() {});
  }

  void _setPeerConnection(RTCPeerConnection? peer) {
    _peerConnection = peer;
    _session.peerConnection = peer;
  }

  void _setDataChannel(RTCDataChannel? channel) {
    _dataChannel = channel;
    _session.dataChannel = channel;
    if (channel != null && !_session.channels.contains(channel)) {
      _session.channels.add(channel);
    }
  }

  void _setRemoteStream(MediaStream stream) {
    _session.remoteStream = stream;
    _remoteRenderer.srcObject = stream;
  }

  void _reattachSessionCallbacks() {
    final peer = _peerConnection;
    if (peer == null) return;

    peer.onConnectionState = (state) {
      _addLog('PeerConnection State: ${state.name}');
      _updateConnectionState();
    };
    peer.onIceConnectionState = (state) {
      _addLog('ICE Connection State: ${state.name}');
      _updateConnectionState();
    };
    peer.onTrack = _handleRestoredTrack;
    peer.onDataChannel = (channel) {
      _addLog('DataChannel received: ${channel.label}');
      _setupDataChannel(channel);
    };

    for (final channel in List<RTCDataChannel>.from(_allChannels)) {
      _setupDataChannel(channel);
    }
  }

  Future<void> _handleRestoredTrack(RTCTrackEvent event) async {
    final params = ref.read(cmWebRtcParamsProvider);
    if (event.track.kind == 'video') {
      event.track.enabled = params.enableVideo;
      if (event.streams.isNotEmpty) {
        _setRemoteStream(event.streams.first);
      } else {
        final stream = await createLocalMediaStream('remote_stream');
        await stream.addTrack(event.track);
        _setRemoteStream(stream);
      }
      if (mounted) setState(() {});
    } else if (event.track.kind == 'audio') {
      event.track.enabled = params.enableAudio;
    }
  }

  void _detachUiCallbacks() {
    final peer = _peerConnection;
    if (peer != null) {
      peer.onIceCandidate = (_) {};
      peer.onConnectionState = (_) {};
      peer.onIceConnectionState = (_) {};
      peer.onTrack = (event) async {
        if (event.track.kind != 'video') return;
        if (event.streams.isNotEmpty) {
          _session.remoteStream = event.streams.first;
          return;
        }
        final stream = await createLocalMediaStream('remote_stream');
        await stream.addTrack(event.track);
        _session.remoteStream = stream;
      };
      peer.onDataChannel = (channel) {
        if (!_session.channels.contains(channel)) {
          _session.channels.add(channel);
        }
        if (channel.state == RTCDataChannelState.RTCDataChannelOpen) {
          _session.dataChannel = channel;
        }
      };
    }

    for (final channel in _allChannels) {
      channel.onDataChannelState = (state) {
        if (state == RTCDataChannelState.RTCDataChannelOpen) {
          _session.dataChannel = channel;
        }
      };
      channel.onMessage = (_) {};
    }
  }

  void _showFullscreenVideo() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: _remoteRenderer.srcObject != null
                  ? RTCVideoView(
                      _remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    )
                  : const Center(
                      child: Text(
                        'No live video stream connected',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton.filled(
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                tooltip: 'Close Fullscreen (Esc)',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleVideoTrack(bool enabled) {
    ref
        .read(cmWebRtcParamsProvider.notifier)
        .update((s) => s.copyWith(enableVideo: enabled));

    // Enable or mute/disable all active video tracks
    final videoTracks = _remoteRenderer.srcObject?.getVideoTracks();
    if (videoTracks != null) {
      for (final track in videoTracks) {
        track.enabled = enabled;
      }
    }

    _peerConnection?.getTransceivers().then((transceivers) {
      for (final tr in transceivers) {
        if (tr.receiver.track?.kind == 'video') {
          tr.receiver.track?.enabled = enabled;
        }
      }
    });

    _addLog('Video track ${enabled ? "ENABLED" : "MUTED/OFF"}.');
    if (mounted) setState(() {});
  }

  void _toggleAudioTrack(bool enabled) {
    ref
        .read(cmWebRtcParamsProvider.notifier)
        .update((s) => s.copyWith(enableAudio: enabled));

    // Enable or mute/disable all active audio tracks
    final audioTracks = _remoteRenderer.srcObject?.getAudioTracks();
    if (audioTracks != null) {
      for (final track in audioTracks) {
        track.enabled = enabled;
      }
    }

    _peerConnection?.getTransceivers().then((transceivers) {
      for (final tr in transceivers) {
        if (tr.receiver.track?.kind == 'audio') {
          tr.receiver.track?.enabled = enabled;
        }
      }
    });

    _addLog('Audio track ${enabled ? "ENABLED" : "MUTED/OFF"}.');
    if (mounted) setState(() {});
  }

  void _addLog(String msg) {
    if (!mounted) return;
    setState(() {
      _logs.add('[${DateTime.now().toString().split('.').first}] $msg');
      if (_logs.length > 100) _logs.removeAt(0);
    });
  }

  @override
  void dispose() {
    _stateTimer?.cancel();
    _statsTimer?.cancel();
    _detachUiCallbacks();
    _webUrlCtrl.dispose();
    _remoteRenderer.srcObject = null;
    _remoteRenderer.dispose();
    _signalingUrl.dispose();
    _roomId.dispose();
    _peerId.dispose();
    _stunServer.dispose();
    _remoteSdpCtrl.dispose();
    _remoteCandidatesCtrl.dispose();
    _localAnswerCtrl.dispose();
    _localCandidatesCtrl.dispose();
    _dataMessage.dispose();
    _byteInputCtrl.dispose();
    _fileInfoCtrl.dispose();
    super.dispose();
  }

  int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _startPacketStatsLogging() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _logWebRtcPacketStats();
    });
  }

  Future<void> _logWebRtcPacketStats() async {
    if (_peerConnection == null) return;
    try {
      final reports = await _peerConnection!.getStats();
      int audioPackets = 0;
      int videoPackets = 0;
      int audioBytes = 0;
      int videoBytes = 0;
      int audioPacketsLost = 0;
      int videoPacketsLost = 0;
      int videoFramesDecoded = 0;

      for (final report in reports) {
        final type = report.type.toLowerCase();
        final vals = report.values;

        final isRtpInbound =
            type == 'inbound-rtp' ||
            type == 'inboundrtp' ||
            (type == 'ssrc' &&
                (vals.containsKey('packetsReceived') ||
                    report.id.contains('recv') ||
                    report.id.contains('inbound')));

        if (isRtpInbound) {
          String? kind =
              vals['kind']?.toString().toLowerCase() ??
              vals['mediaType']?.toString().toLowerCase();

          if (kind == null) {
            final idLower = report.id.toLowerCase();
            if (idLower.contains('video') ||
                vals.containsKey('framesDecoded') ||
                vals.containsKey('framesReceived')) {
              kind = 'video';
            } else if (idLower.contains('audio') ||
                vals.containsKey('audioLevel')) {
              kind = 'audio';
            }
          }

          final pkts = _parseInt(vals['packetsReceived']);
          final bytes = _parseInt(vals['bytesReceived']);
          final lost = _parseInt(vals['packetsLost']);

          if (kind == 'audio') {
            audioPackets += pkts;
            audioBytes += bytes;
            audioPacketsLost += lost;
          } else if (kind == 'video') {
            videoPackets += pkts;
            videoBytes += bytes;
            videoPacketsLost += lost;
            videoFramesDecoded += _parseInt(
              vals['framesDecoded'] ?? vals['framesReceived'],
            );
          }
        }
      }

      final deltaAudioPkts = _hasRecordedInitialStats
          ? (audioPackets - _prevAudioPackets).clamp(0, 1 << 31)
          : audioPackets;
      final deltaVideoPkts = _hasRecordedInitialStats
          ? (videoPackets - _prevVideoPackets).clamp(0, 1 << 31)
          : videoPackets;
      final deltaAudioBytes = _hasRecordedInitialStats
          ? (audioBytes - _prevAudioBytes).clamp(0, 1 << 31)
          : audioBytes;
      final deltaVideoBytes = _hasRecordedInitialStats
          ? (videoBytes - _prevVideoBytes).clamp(0, 1 << 31)
          : videoBytes;

      _prevAudioPackets = audioPackets;
      _prevVideoPackets = videoPackets;
      _prevAudioBytes = audioBytes;
      _prevVideoBytes = videoBytes;
      _hasRecordedInitialStats = true;

      final timestampStr = DateTime.now().toString().split('.').first;
      final logMsg =
          '[$timestampStr] [WebRTC 1-min Stats] Packets Received -> '
          'Audio: $audioPackets packets (+$deltaAudioPkts/min, ${_formatBytes(deltaAudioBytes)}/min, lost: $audioPacketsLost) | '
          'Video: $videoPackets packets (+$deltaVideoPkts/min, ${_formatBytes(deltaVideoBytes)}/min, decoded: $videoFramesDecoded, lost: $videoPacketsLost)';

      debugPrint(logMsg);
      _addLog(
        '[Stats 1m] Packets: Audio=$audioPackets (+$deltaAudioPkts), Video=$videoPackets (+$deltaVideoPkts)',
      );
    } catch (e) {
      debugPrint('[WebRTC Stats Error] Failed to retrieve stats: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    final stun = _stunServer.text.trim();
    final configuration = <String, dynamic>{
      'iceServers': [
        if (stun.isNotEmpty)
          {'urls': stun}
        else
          {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };

    final constraints = <String, dynamic>{
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    _setPeerConnection(await createPeerConnection(configuration, constraints));
    _startPacketStatsLogging();

    final params = ref.read(cmWebRtcParamsProvider);
    if (params.enableVideo) {
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
    }
    if (params.enableAudio) {
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
    }

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        final line = 'a=${candidate.candidate}';
        _addLog('Local Candidate: $line');
        final cur = _localCandidatesCtrl.text;
        _localCandidatesCtrl.text = cur.isEmpty ? line : '$cur\n$line';

        // Automatically append local candidates into _localAnswerCtrl if answer exists
        if (_localAnswerCtrl.text.isNotEmpty &&
            !_localAnswerCtrl.text.contains(line)) {
          _localAnswerCtrl.text = '${_localAnswerCtrl.text.trim()}\n$line';
        }

        ref
            .read(cmWebRtcParamsProvider.notifier)
            .update(
              (s) => s.copyWith(
                localIceCandidates: _localCandidatesCtrl.text,
                localSdpAnswer: _localAnswerCtrl.text,
              ),
            );
      }
    };

    _peerConnection!.onConnectionState = (state) {
      _addLog('PeerConnection State: ${state.name}');
      _updateConnectionState();
    };

    _peerConnection!.onIceConnectionState = (state) {
      _addLog('ICE Connection State: ${state.name}');
      _updateConnectionState();
    };

    _peerConnection!.onTrack = (event) async {
      _addLog('Track received: ${event.track.kind}');
      final params = ref.read(cmWebRtcParamsProvider);
      if (event.track.kind == 'video') {
        event.track.enabled = params.enableVideo;
        if (event.streams.isNotEmpty) {
          setState(() {
            _setRemoteStream(event.streams[0]);
          });
        } else {
          try {
            final newStream = await createLocalMediaStream('remote_stream');
            await newStream.addTrack(event.track);
            setState(() {
              _setRemoteStream(newStream);
            });
          } catch (e) {
            _addLog('Error setting up standalone track: $e');
          }
        }
      } else if (event.track.kind == 'audio') {
        event.track.enabled = params.enableAudio;
      }
    };

    _peerConnection!.onDataChannel = (channel) {
      _addLog('DataChannel received: ${channel.label}');
      _setupDataChannel(channel);
    };
  }

  final List<RTCDataChannel> _allChannels = [];
  Timer? _stateTimer;

  void _startStatePolling() {
    _stateTimer?.cancel();
    _stateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      for (final channel in _allChannels) {
        try {
          if (channel.state == RTCDataChannelState.RTCDataChannelOpen) {
            if (_dataChannel != channel) {
              _setDataChannel(channel);
              _addLog(
                'Polled DataChannel "${channel.label}" is OPEN and ACTIVE!',
              );
            }
            _updateConnectionState();
            break;
          }
        } catch (_) {}
      }
    });
  }

  void _updateConnectionState() {
    final dcState = _dataChannel?.state;
    final isConnected = dcState == RTCDataChannelState.RTCDataChannelOpen;

    ref
        .read(cmWebRtcParamsProvider.notifier)
        .update((s) => s.copyWith(isConnected: isConnected));
    if (mounted) setState(() {});
  }

  void _setupDataChannel(RTCDataChannel channel) {
    _addLog(
      'Setting up DataChannel "${channel.label}" (state: ${channel.state?.name ?? 'unknown'})',
    );

    if (!_allChannels.contains(channel)) {
      _allChannels.add(channel);
    }
    if (!_session.channels.contains(channel)) {
      _session.channels.add(channel);
    }

    // Only set as primary _dataChannel if none exists or if this channel is open
    if (_dataChannel == null ||
        channel.state == RTCDataChannelState.RTCDataChannelOpen) {
      _setDataChannel(channel);
    }

    channel.onDataChannelState = (state) {
      _addLog('DataChannel "${channel.label}" State changed to: ${state.name}');
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _setDataChannel(channel);
        _addLog(
          'Active DataChannel set to "${channel.label}". Ready for messaging!',
        );
      }
      _updateConnectionState();
    };

    channel.onMessage = (data) {
      if (data.isBinary) {
        final bytes = data.binary;
        if (bytes.isNotEmpty) {
          final type = bytes[0];
          final bd = ByteData.sublistView(bytes);

          // 0x01: Raw Byte Array / Sensor Data Envelope
          if (type == kMsgTypeRawByteArray && bytes.length >= 2) {
            Uint8List payload;
            if (bytes.length >= 5 &&
                bd.getUint32(1, Endian.big) == bytes.length - 5) {
              payload = bytes.sublist(5);
            } else {
              payload = bytes.sublist(1);
            }
            final hexStr = _formatBytesHex(payload);
            final asciiPreview = _toPrintableAscii(payload);
            debugPrint(
              '[WebRTC DataChannel Received Framed Array [0x01]] [${channel.label}] (Length: ${payload.length} bytes): $hexStr | ASCII: "$asciiPreview"',
            );
            _addLog(
              'Received Framed Array [0x01] [${channel.label}] (${payload.length} bytes): $hexStr',
            );
            return;
          }

          // 0x02: File Transfer Start Envelope
          if (type == kMsgTypeFileStart && bytes.length >= 8) {
            final nameLen = bytes[1];
            if (bytes.length >= 2 + nameLen + 6) {
              final fileName = utf8.decode(bytes.sublist(2, 2 + nameLen));
              final fileSize = bd.getUint32(2 + nameLen, Endian.big);
              final totalChunks = bd.getUint16(2 + nameLen + 4, Endian.big);
              debugPrint(
                '[WebRTC DataChannel File Start [0x02]] Filename: "$fileName", Size: $fileSize bytes (${_formatBytes(fileSize)}), Total Chunks: $totalChunks',
              );
              _addLog(
                'Incoming File [0x02]: "$fileName" (${_formatBytes(fileSize)}, $totalChunks chunks)',
              );
              return;
            }
          }

          // 0x03: File Chunk Envelope
          if (type == kMsgTypeFileChunk && bytes.length >= 5) {
            final chunkIndex = bd.getUint16(1, Endian.big);
            final chunkLen = bd.getUint16(3, Endian.big);
            final chunkData = bytes.length >= 5 + chunkLen
                ? bytes.sublist(5, 5 + chunkLen)
                : bytes.sublist(5);
            debugPrint(
              '[WebRTC DataChannel File Chunk [0x03]] Chunk #${chunkIndex + 1} ($chunkLen bytes received, sample: ${_formatBytesHex(chunkData.sublist(0, chunkData.length > 8 ? 8 : chunkData.length))})',
            );
            _addLog(
              'Received File Chunk #${chunkIndex + 1} (${_formatBytes(chunkLen)})',
            );
            return;
          }

          // 0x04: File Transfer Complete Envelope
          if (type == kMsgTypeFileEnd && bytes.length >= 7) {
            final totalChunks = bd.getUint16(1, Endian.big);
            final totalBytes = bd.getUint32(3, Endian.big);
            debugPrint(
              '[WebRTC DataChannel File Complete [0x04]] Finished transfer of $totalBytes bytes ($totalChunks chunks).',
            );
            _addLog(
              'File Transfer Complete [0x04]: ${_formatBytes(totalBytes)} in $totalChunks chunks',
            );
            return;
          }
        }

        // Generic / Raw Unframed Binary Fallback
        final hexStr = _formatBytesHex(bytes);
        final asciiPreview = _toPrintableAscii(bytes);
        debugPrint(
          '[WebRTC DataChannel Received Binary (Raw)] [${channel.label}] (${bytes.length} bytes): $hexStr | ASCII: "$asciiPreview"',
        );
        _addLog(
          'Received Binary [${channel.label}] (${bytes.length} bytes): $hexStr',
        );
      } else {
        debugPrint(
          '[WebRTC DataChannel Received Text] [${channel.label}]: ${data.text}',
        );
        _addLog('Received Data [${channel.label}]: ${data.text}');
      }
    };

    if (channel.state == RTCDataChannelState.RTCDataChannelOpen) {
      _setDataChannel(channel);
      _updateConnectionState();
    }

    _startStatePolling();
  }

  Map<String, dynamic> _cleanAndNormalizeTerminalInput(String rawInput) {
    final sdpLines = <String>[];
    final candidateLines = <String>[];

    final rawLines = rawInput
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');

    for (var line in rawLines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('a=candidate:') || line.startsWith('candidate:')) {
        final candStr = line.startsWith('a=') ? line : 'a=$line';
        candidateLines.add(candStr);
        continue;
      }

      // Filter SDP header lines matching standard RFC 4566 SDP format key=value (e.g. v=, o=, s=, t=, a=, m=, c=, b=)
      if (RegExp(r'^[vostamcbkrzuep]=.+$').hasMatch(line)) {
        sdpLines.add(line);
      }
    }

    final normalizedSdp = sdpLines.isNotEmpty
        ? '${sdpLines.join('\r\n')}\r\n'
        : '';
    return {
      'sdp': normalizedSdp,
      'candidates': candidateLines,
      'sdpLines': sdpLines,
    };
  }

  Future<void> _processManualOffer() async {
    final rawInput = _remoteSdpCtrl.text.trim();
    if (rawInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please paste the Local Description (Offer) from ./offerer',
          ),
        ),
      );
      return;
    }

    final parsed = _cleanAndNormalizeTerminalInput(rawInput);
    final offerSdpText = parsed['sdp'] as String;
    final extractedCandidates = parsed['candidates'] as List<String>;

    if (offerSdpText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No valid SDP lines (e.g. v=0, o=rtc...) found in input.',
          ),
        ),
      );
      return;
    }

    try {
      if (_peerConnection == null) {
        await _createPeerConnection();
      }

      // Clean display SDP and populate extracted candidate input box if empty
      final cleanDisplaySdp = (parsed['sdpLines'] as List<String>).join('\n');
      _remoteSdpCtrl.text = cleanDisplaySdp;

      if (extractedCandidates.isNotEmpty &&
          _remoteCandidatesCtrl.text.trim().isEmpty) {
        _remoteCandidatesCtrl.text = extractedCandidates.join('\n');
      }

      // Create local data channel if needed
      final dcInit = RTCDataChannelInit()..id = 0;
      final dc = await _peerConnection!.createDataChannel(
        'datachannel',
        dcInit,
      );
      _setupDataChannel(dc);

      // Set Remote Description (Offer) with CRLF normalized SDP
      final offer = RTCSessionDescription(offerSdpText, 'offer');
      await _peerConnection!.setRemoteDescription(offer);
      _addLog('Remote Description (Offer) set successfully.');

      // Process candidate lines from candidates box and extracted candidates
      final candBoxLines = _remoteCandidatesCtrl.text
          .split('\n')
          .map((l) => l.trim())
          .where(
            (l) => l.startsWith('a=candidate:') || l.startsWith('candidate:'),
          );
      final allCandidates = <String>{...extractedCandidates, ...candBoxLines};

      for (final candLine in allCandidates) {
        final candStr = candLine.startsWith('a=')
            ? candLine.substring(2)
            : candLine;
        final cand = RTCIceCandidate(candStr, '0', 0);
        await _peerConnection!.addCandidate(cand);
        _addLog('Added Remote Candidate: $candStr');
      }

      // Create Answer
      final params = ref.read(cmWebRtcParamsProvider);
      final answer = await _peerConnection!.createAnswer({
        'mandatory': {
          'OfferToReceiveAudio': params.enableAudio,
          'OfferToReceiveVideo': params.enableVideo,
        },
        'optional': [],
      });
      await _peerConnection!.setLocalDescription(answer);

      // Embed gathered candidates directly into Answer SDP for 1-step paste
      String fullAnswerSdp = (answer.sdp ?? '').trim();
      if (_localCandidatesCtrl.text.isNotEmpty) {
        final candLines = _localCandidatesCtrl.text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty);
        for (final cand in candLines) {
          final candLine = cand.startsWith('a=') ? cand : 'a=$cand';
          if (!fullAnswerSdp.contains(candLine)) {
            fullAnswerSdp += '\r\n$candLine';
          }
        }
      }

      _localAnswerCtrl.text = fullAnswerSdp;
      _addLog('Local Answer SDP (with embedded ICE candidates) generated.');

      ref
          .read(cmWebRtcParamsProvider.notifier)
          .update(
            (s) => s.copyWith(
              remoteSdpOffer: cleanDisplaySdp,
              localSdpAnswer: _localAnswerCtrl.text,
            ),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Local Answer SDP generated! Copy and paste to ./offerer',
          ),
        ),
      );
    } catch (e) {
      _addLog('Error processing offer: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to parse SDP Offer: $e')));
    }
  }

  Future<void> _addRemoteCandidatesManually() async {
    if (_peerConnection == null) return;
    final lines = _remoteCandidatesCtrl.text.split('\n');
    int added = 0;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('a=candidate:') ||
          trimmed.startsWith('candidate:')) {
        final candStr = trimmed.startsWith('a=')
            ? trimmed.substring(2)
            : trimmed;
        final cand = RTCIceCandidate(candStr, '0', 0);
        await _peerConnection!.addCandidate(cand);
        added++;
      }
    }
    _addLog('Added $added remote candidates manually.');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $added Remote Candidates to PeerConnection'),
      ),
    );
  }

  RTCDataChannelState? get _safeDataChannelState {
    try {
      return _dataChannel?.state;
    } catch (_) {
      return null;
    }
  }

  String _formatBytesHex(Uint8List bytes, {int maxLen = 32}) {
    final hexParts = bytes
        .take(maxLen)
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .toList();
    final suffix = bytes.length > maxLen
        ? ' ... (+${bytes.length - maxLen} bytes)'
        : '';
    return '${hexParts.join(' ')}$suffix';
  }

  String _toPrintableAscii(Uint8List bytes, {int maxLen = 32}) {
    final chars = bytes.take(maxLen).map((b) {
      if (b >= 32 && b <= 126) return String.fromCharCode(b);
      return '.';
    }).join();
    return chars;
  }

  Uint8List? _parseByteArray(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;

    s = s
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('{', '')
        .replaceAll('}', '');

    // Comma-separated (e.g. "0x01, 0x02, 0xAA" or "1, 2, 170")
    if (s.contains(',')) {
      final tokens = s
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final bytes = <int>[];
      for (final t in tokens) {
        int? val;
        if (t.toLowerCase().startsWith('0x')) {
          val = int.tryParse(t.substring(2), radix: 16);
        } else {
          val = int.tryParse(t, radix: 16) ?? int.tryParse(t);
        }
        if (val == null || val < 0 || val > 255) return null;
        bytes.add(val);
      }
      return Uint8List.fromList(bytes);
    }

    // Space-separated or hex prefixes (e.g. "01 02 AA FF" or "\x01\x02\xaa\xff" or "0x01 0x02")
    if (s.contains(' ') || s.contains('0x') || s.contains(r'\x')) {
      final tokens = s
          .replaceAll(r'\x', ' ')
          .replaceAll('0x', ' ')
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty)
          .toList();
      final bytes = <int>[];
      for (final t in tokens) {
        final val = int.tryParse(t, radix: 16);
        if (val == null || val < 0 || val > 255) return null;
        bytes.add(val);
      }
      return Uint8List.fromList(bytes);
    }

    // Continuous hex string (e.g. "0102AAFF00")
    if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(s) && s.length % 2 == 0) {
      final bytes = <int>[];
      for (int i = 0; i < s.length; i += 2) {
        final byteStr = s.substring(i, i + 2);
        final val = int.tryParse(byteStr, radix: 16);
        if (val == null) return null;
        bytes.add(val);
      }
      return Uint8List.fromList(bytes);
    }

    return null;
  }

  Future<bool> _reopenDataChannel() async {
    if (_peerConnection == null) {
      _addLog('Cannot reopen DataChannel: PeerConnection is not established.');
      return false;
    }
    try {
      _addLog(
        'Re-creating DataChannel "datachannel" on active PeerConnection...',
      );
      final dcInit = RTCDataChannelInit()..id = 0;
      final dc = await _peerConnection!.createDataChannel(
        'datachannel',
        dcInit,
      );
      _setupDataChannel(dc);
      _addLog('New DataChannel created. Waiting for open state...');
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_safeDataChannelState == RTCDataChannelState.RTCDataChannelOpen) {
          _addLog('DataChannel successfully reopened and ready for messaging!');
          return true;
        }
      }
      return _safeDataChannelState == RTCDataChannelState.RTCDataChannelOpen;
    } catch (e) {
      _addLog('Error recreating DataChannel: $e');
      return false;
    }
  }

  void _sendByteArray([Uint8List? directBytes]) async {
    Uint8List bytes;
    if (directBytes != null) {
      bytes = directBytes;
    } else {
      final raw = _byteInputCtrl.text.trim();
      if (raw.isEmpty) return;
      final parsed = _parseByteArray(raw);
      if (parsed == null || parsed.isEmpty) {
        _addLog(
          'Error: Invalid byte array format. Use Hex (e.g. 01 02 AA FF or 0x01, 0x02) or Decimal (1, 2, 170).',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid byte array format. Example: 01 02 AA FF or 0x01, 0x02',
              ),
            ),
          );
        }
        return;
      }
      bytes = parsed;
    }

    var state = _safeDataChannelState;
    if (_dataChannel == null ||
        state != RTCDataChannelState.RTCDataChannelOpen) {
      if (_peerConnection != null) {
        _addLog(
          'DataChannel is not open (State: "$state"). Attempting auto-reopen...',
        );
        await _reopenDataChannel();
        state = _safeDataChannelState;
      }
    }

    if (_dataChannel != null &&
        state == RTCDataChannelState.RTCDataChannelOpen) {
      try {
        final params = ref.read(cmWebRtcParamsProvider);
        Uint8List packetToSend;

        if (params.useBinaryHeaderEnvelope) {
          // 0x01 (Type Identifier) | Raw Payload
          packetToSend = Uint8List(1 + bytes.length);
          packetToSend[0] = kMsgTypeRawByteArray;
          packetToSend.setRange(1, 1 + bytes.length, bytes);
        } else {
          packetToSend = bytes;
        }

        final msg = RTCDataChannelMessage.fromBinary(packetToSend);
        _dataChannel!.send(msg);
        final hexStr = _formatBytesHex(bytes);
        final tag = params.useBinaryHeaderEnvelope
            ? 'Framed Binary [0x01]'
            : 'Raw Binary';
        debugPrint(
          '[WebRTC DataChannel] Sent $tag [${_dataChannel!.label}] (${bytes.length} bytes): $hexStr',
        );
        _addLog(
          'Sent $tag [${_dataChannel!.label}] (${bytes.length} bytes): $hexStr',
        );
      } catch (e) {
        _addLog('Error sending binary data over DataChannel: $e');
      }
    } else {
      final curState = state?.name ?? 'closed';
      _addLog('Cannot send binary. DataChannel state is "$curState".');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'DataChannel is closed (State: $curState). Re-open DataChannel or re-connect.',
          ),
        ),
      );
    }
  }

  void _sendDataMessage() async {
    final text = _dataMessage.text.trim();
    if (text.isEmpty) return;

    var state = _safeDataChannelState;
    if (_dataChannel == null ||
        state != RTCDataChannelState.RTCDataChannelOpen) {
      if (_peerConnection != null) {
        _addLog(
          'DataChannel is not open (State: "$state"). Attempting auto-reopen...',
        );
        await _reopenDataChannel();
        state = _safeDataChannelState;
      }
    }

    if (_dataChannel != null &&
        state == RTCDataChannelState.RTCDataChannelOpen) {
      try {
        _dataChannel!.send(RTCDataChannelMessage(text));
        debugPrint(
          '[WebRTC DataChannel] Sent Text [${_dataChannel!.label}]: "$text"',
        );
        _addLog('Sent Data [${_dataChannel!.label}]: "$text"');
        _dataMessage.clear();
      } catch (e) {
        _addLog('Error sending message over DataChannel: $e');
      }
    } else {
      final curState = state?.name ?? 'closed';
      _addLog('Cannot send data. DataChannel state is "$curState".');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DataChannel is not open yet (State: $curState).'),
        ),
      );
    }
  }

  Future<void> _pickFile({bool loadToHexField = false}) async {
    try {
      final result = await FilePicker.pickFiles();
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final filePath = file.path;
      if (filePath == null) return;

      setState(() {
        _selectedFilePath = filePath;
        _selectedFileName = file.name;
        _fileInfoCtrl.text = '${file.name} (${_formatBytes(file.size)})';
      });

      _addLog('Selected file: ${file.name} (${_formatBytes(file.size)})');

      if (loadToHexField) {
        final f = File(filePath);
        final bytes = await f.readAsBytes();
        final previewBytes = bytes.length > 256 ? bytes.sublist(0, 256) : bytes;
        final hexStr = _formatBytesHex(previewBytes, maxLen: 256);
        _byteInputCtrl.text = hexStr;
        _addLog(
          'Loaded ${bytes.length} file bytes into hex field (previewing ${previewBytes.length} bytes).',
        );
      }
    } catch (e) {
      _addLog('Error picking file: $e');
    }
  }

  Future<void> _sendFile({String mode = 'auto', int chunkSize = 16384}) async {
    if (_selectedFilePath == null || !File(_selectedFilePath!).existsSync()) {
      await _pickFile();
      if (_selectedFilePath == null) return;
    }

    var state = _safeDataChannelState;
    if (_dataChannel == null ||
        state != RTCDataChannelState.RTCDataChannelOpen) {
      if (_peerConnection != null) {
        _addLog(
          'DataChannel is not open (State: "$state"). Attempting auto-reopen...',
        );
        await _reopenDataChannel();
        state = _safeDataChannelState;
      }
    }

    if (_dataChannel == null ||
        state != RTCDataChannelState.RTCDataChannelOpen) {
      final curState = state?.name ?? 'closed';
      _addLog(
        'Cannot send file. DataChannel is not open (State: "$curState").',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'DataChannel is closed (State: $curState). Re-open DataChannel or re-connect.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final f = File(_selectedFilePath!);
      final fileName =
          _selectedFileName ?? f.path.split(Platform.pathSeparator).last;
      final bytes = await f.readAsBytes();
      final totalBytes = bytes.length;
      final params = ref.read(cmWebRtcParamsProvider);

      setState(() {
        _isSendingFile = true;
        _fileSendProgress = 0.0;
      });

      _addLog(
        'Starting DataChannel transfer for "$fileName" (${_formatBytes(totalBytes)})...',
      );

      final effectiveMode = mode == 'auto'
          ? (params.useBinaryHeaderEnvelope
                ? (totalBytes <= 524288 ? 'single_named' : 'chunked_02')
                : 'raw')
          : mode;

      if (effectiveMode == 'single_named') {
        // [0x02, nameLen (1B), ...nameBytes, ...fileBytes]
        final nameBytes = utf8.encode(fileName);
        final nameLen = nameBytes.length.clamp(1, 255);
        final packetToSend = Uint8List(1 + 1 + nameLen + totalBytes);
        packetToSend[0] = kMsgTypeFileStart; // 0x02
        packetToSend[1] = nameLen;
        packetToSend.setRange(2, 2 + nameLen, nameBytes.sublist(0, nameLen));
        packetToSend.setRange(2 + nameLen, 2 + nameLen + totalBytes, bytes);

        _dataChannel!.send(RTCDataChannelMessage.fromBinary(packetToSend));
        if (mounted) setState(() => _fileSendProgress = 1.0);

        final hexSample = _formatBytesHex(
          bytes.sublist(0, bytes.length > 16 ? 16 : bytes.length),
        );
        debugPrint(
          '[WebRTC DataChannel] Sent File "$fileName" ($totalBytes bytes as [0x02 + Filename + Data], sample: $hexSample)',
        );
        _addLog(
          'File "$fileName" sent successfully ($totalBytes bytes as [0x02 + Filename + Data]).',
        );
      } else if (effectiveMode == 'single_unnamed') {
        // [0x02, ...fileBytes]
        final packetToSend = Uint8List(1 + totalBytes);
        packetToSend[0] = kMsgTypeFileStart; // 0x02
        packetToSend.setRange(1, 1 + totalBytes, bytes);

        _dataChannel!.send(RTCDataChannelMessage.fromBinary(packetToSend));
        if (mounted) setState(() => _fileSendProgress = 1.0);

        debugPrint(
          '[WebRTC DataChannel] Sent File "$fileName" ($totalBytes bytes as [0x02 + Data])',
        );
        _addLog(
          'File "$fileName" sent successfully ($totalBytes bytes as [0x02 + Data]).',
        );
      } else if (effectiveMode == 'raw') {
        // Pure raw binary payload (no header)
        _dataChannel!.send(RTCDataChannelMessage.fromBinary(bytes));
        if (mounted) setState(() => _fileSendProgress = 1.0);

        debugPrint(
          '[WebRTC DataChannel] Sent File "$fileName" ($totalBytes bytes pure raw binary)',
        );
        _addLog(
          'File "$fileName" sent successfully ($totalBytes bytes raw binary).',
        );
      } else if (effectiveMode == 'chunked_02') {
        // Chunks where each chunk is prefixed by 0x02
        final totalChunks = (totalBytes / chunkSize).ceil().clamp(1, 65535);
        int sentBytes = 0;

        for (int i = 0; i < totalChunks; i++) {
          if (!_isSendingFile) break;
          final start = i * chunkSize;
          final end = (start + chunkSize).clamp(0, totalBytes);
          final chunk = bytes.sublist(start, end);

          final packetToSend = Uint8List(1 + chunk.length);
          packetToSend[0] = kMsgTypeFileStart; // 0x02
          packetToSend.setRange(1, 1 + chunk.length, chunk);

          _dataChannel!.send(RTCDataChannelMessage.fromBinary(packetToSend));
          sentBytes += chunk.length;

          if (mounted) {
            setState(() => _fileSendProgress = sentBytes / totalBytes);
          }
          await Future.delayed(const Duration(milliseconds: 10));
        }

        debugPrint(
          '[WebRTC DataChannel] Sent File "$fileName" ($totalBytes bytes in $totalChunks chunks with 0x02 header)',
        );
        _addLog(
          'File "$fileName" sent successfully ($totalBytes bytes in $totalChunks chunks with 0x02).',
        );
      } else if (effectiveMode == 'multi_chunked') {
        // Multi-phase protocol: 0x02 Start / 0x03 Chunks / 0x04 End
        final totalChunks = (totalBytes / chunkSize).ceil().clamp(1, 65535);
        final nameBytes = utf8.encode(fileName);
        final nameLen = nameBytes.length.clamp(1, 255);
        final startPacket = Uint8List(1 + 1 + nameLen + 4 + 2);
        final bdStart = ByteData.sublistView(startPacket);
        bdStart.setUint8(0, kMsgTypeFileStart);
        bdStart.setUint8(1, nameLen);
        startPacket.setRange(2, 2 + nameLen, nameBytes.sublist(0, nameLen));
        bdStart.setUint32(2 + nameLen, totalBytes, Endian.big);
        bdStart.setUint16(2 + nameLen + 4, totalChunks, Endian.big);

        _dataChannel!.send(RTCDataChannelMessage.fromBinary(startPacket));
        await Future.delayed(const Duration(milliseconds: 10));

        int sentBytes = 0;
        for (int i = 0; i < totalChunks; i++) {
          if (!_isSendingFile) break;
          final start = i * chunkSize;
          final end = (start + chunkSize).clamp(0, totalBytes);
          final chunk = bytes.sublist(start, end);

          final packetToSend = Uint8List(5 + chunk.length);
          final bdChunk = ByteData.sublistView(packetToSend);
          bdChunk.setUint8(0, kMsgTypeFileChunk);
          bdChunk.setUint16(1, i, Endian.big);
          bdChunk.setUint16(3, chunk.length, Endian.big);
          packetToSend.setRange(5, 5 + chunk.length, chunk);

          _dataChannel!.send(RTCDataChannelMessage.fromBinary(packetToSend));
          sentBytes += chunk.length;

          if (mounted) {
            setState(() => _fileSendProgress = sentBytes / totalBytes);
          }
          await Future.delayed(const Duration(milliseconds: 10));
        }

        final endPacket = Uint8List(7);
        final bdEnd = ByteData.sublistView(endPacket);
        bdEnd.setUint8(0, kMsgTypeFileEnd);
        bdEnd.setUint16(1, totalChunks, Endian.big);
        bdEnd.setUint32(3, totalBytes, Endian.big);
        _dataChannel!.send(RTCDataChannelMessage.fromBinary(endPacket));

        debugPrint(
          '[WebRTC DataChannel] Sent File "$fileName" ($totalBytes bytes in $totalChunks chunks via 0x02/0x03/0x04)',
        );
        _addLog(
          'File "$fileName" sent successfully ($totalBytes bytes in $totalChunks chunks via 0x02/0x03/0x04).',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File "$fileName" (${_formatBytes(totalBytes)}) sent over DataChannel!',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[WebRTC DataChannel File Error] $e');
      _addLog('Error sending file: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send file: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingFile = false;
        });
      }
    }
  }

  WebSocket? _wsSocket;

  Future<void> _connectWebSocketSignaling() async {
    var url = _signalingUrl.text.trim();
    final localId = _peerId.text.trim().isEmpty
        ? 'sanc_term'
        : _peerId.text.trim();
    final targetId = _roomId.text.trim();

    // Auto-append /<localId> if URL path is empty
    try {
      final uri = Uri.parse(url);
      if (uri.path.isEmpty || uri.path == '/') {
        url = '${url.replaceAll(RegExp(r'/$'), '')}/$localId';
      }
    } catch (_) {}

    _addLog('Connecting WebSocket Signaling Server: $url...');
    try {
      _wsSocket = await WebSocket.connect(url).timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          throw TimeoutException(
            'Connection timed out (Host IP or Port unreachable)',
          );
        },
      );
      _addLog('WebSocket Signaling connected as "$localId".');

      // Register client ID with signaling-server.py
      _wsSocket!.add(jsonEncode({'type': 'id', 'id': localId}));

      _wsSocket!.listen(
        (data) async {
          _addLog('WS Received: $data');
          try {
            final jsonMap = jsonDecode(data.toString()) as Map<String, dynamic>;
            final type = jsonMap['type'] as String?;
            final senderId = (jsonMap['id'] ?? jsonMap['src'] ?? targetId)
                .toString();

            // Ignore echoed messages sent by ourselves
            if (senderId == localId) return;

            if (type == 'offer') {
              String? sdp;
              if (jsonMap['description'] is String) {
                sdp = jsonMap['description'] as String;
              } else if (jsonMap['description'] is Map) {
                sdp = jsonMap['description']['sdp'] as String?;
              } else if (jsonMap['sdp'] is String) {
                sdp = jsonMap['sdp'] as String;
              }

              if (sdp != null) {
                // Always close old peer connection to ensure fresh ICE ufrag/pwd credentials
                await _peerConnection?.close();
                _setPeerConnection(null);
                await _createPeerConnection();

                // Auto-sync target Room ID in UI if senderId is provided
                if (senderId.isNotEmpty &&
                    senderId != 'null' &&
                    senderId != localId) {
                  _roomId.text = senderId;
                }

                // Normalize line endings to CRLF (\r\n) without stripping candidate lines
                final normalizedSdp =
                    '${sdp.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).join('\r\n')}\r\n';

                final offer = RTCSessionDescription(normalizedSdp, 'offer');
                await _peerConnection!.setRemoteDescription(offer);

                final params = ref.read(cmWebRtcParamsProvider);
                final answer = await _peerConnection!.createAnswer({
                  'mandatory': {
                    'OfferToReceiveAudio': params.enableAudio,
                    'OfferToReceiveVideo': params.enableVideo,
                  },
                  'optional': [],
                });
                await _peerConnection!.setLocalDescription(answer);

                // Give 150ms for local ICE candidates to gather and embed in Answer SDP
                await Future.delayed(const Duration(milliseconds: 150));

                String fullAnswerSdp = (answer.sdp ?? '').trim();
                if (_localCandidatesCtrl.text.isNotEmpty) {
                  final candLines = _localCandidatesCtrl.text
                      .split('\n')
                      .map((l) => l.trim())
                      .where((l) => l.isNotEmpty);
                  for (final cand in candLines) {
                    final candLine = cand.startsWith('a=') ? cand : 'a=$cand';
                    if (!fullAnswerSdp.contains(candLine)) {
                      fullAnswerSdp += '\r\n$candLine';
                    }
                  }
                }
                fullAnswerSdp =
                    '${fullAnswerSdp.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).join('\r\n')}\r\n';

                final answerMap = <String, dynamic>{
                  'type': 'answer',
                  'description': fullAnswerSdp,
                  'sdp': fullAnswerSdp,
                };
                if (jsonMap.containsKey('id') ||
                    (senderId.isNotEmpty &&
                        senderId != 'null' &&
                        senderId != localId)) {
                  answerMap['id'] = jsonMap['id'] ?? senderId;
                }
                final answerMsg = jsonEncode(answerMap);
                _wsSocket!.add(answerMsg);
                _isSignalingDescriptionSent = true;
                _addLog('Sent SDP Answer via WebSocket.');
              }
            } else if (type == 'answer') {
              String? sdp;
              if (jsonMap['description'] is String) {
                sdp = jsonMap['description'] as String;
              } else if (jsonMap['description'] is Map) {
                sdp = jsonMap['description']['sdp'] as String?;
              } else if (jsonMap['sdp'] is String) {
                sdp = jsonMap['sdp'] as String;
              }

              if (sdp != null && _peerConnection != null) {
                final parsed = _cleanAndNormalizeTerminalInput(sdp);
                final answer = RTCSessionDescription(
                  parsed['sdp'] as String,
                  'answer',
                );
                await _peerConnection!.setRemoteDescription(answer);
                _addLog('Set Remote SDP Answer via WebSocket.');
              }
            } else if (type == 'candidate') {
              String? candStr;
              String mid = '0';
              int mline = 0;

              if (jsonMap['candidate'] is Map) {
                final cMap = jsonMap['candidate'] as Map;
                candStr = cMap['candidate'] as String?;
                mid = (cMap['sdpMid'] ?? cMap['mid'] ?? '0').toString();
                mline =
                    (cMap['sdpMLineIndex'] ?? cMap['mlineindex'] ?? 0) as int;
              } else if (jsonMap['candidate'] is String) {
                candStr = jsonMap['candidate'] as String;
                mid = (jsonMap['mid'] ?? '0').toString();
                mline = (jsonMap['mlineindex'] ?? 0) as int;
              }

              if (candStr != null && _peerConnection != null) {
                final candLine = candStr.startsWith('a=')
                    ? candStr.substring(2)
                    : candStr;
                final cand = RTCIceCandidate(candLine, mid, mline);
                await _peerConnection!.addCandidate(cand);
                _addLog('Added ICE Candidate via WebSocket.');
              }
            }
          } catch (e) {
            _addLog('Error parsing WS message: $e');
          }
        },
        onDone: () {
          _addLog('WebSocket closed.');
          ref
              .read(cmWebRtcParamsProvider.notifier)
              .update((s) => s.copyWith(isConnected: false));
        },
        onError: (err) {
          _addLog('WebSocket error: $err');
        },
      );

      if (_peerConnection == null) await _createPeerConnection();
      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          final rawCand = candidate.candidate!;
          final candLine = rawCand.startsWith('a=')
              ? rawCand.substring(2)
              : rawCand;

          // Record in local candidates text for embedding
          if (!_localCandidatesCtrl.text.contains(candLine)) {
            _localCandidatesCtrl.text = _localCandidatesCtrl.text.isEmpty
                ? candLine
                : '${_localCandidatesCtrl.text}\n$candLine';
          }

          final activeTargetId = _roomId.text.trim();
          if (_wsSocket != null && _isSignalingDescriptionSent) {
            final candMap = <String, dynamic>{
              'type': 'candidate',
              'candidate': candLine,
              'mid': candidate.sdpMid ?? '0',
            };
            if (activeTargetId.isNotEmpty) {
              candMap['id'] = activeTargetId;
            }
            final candMsg = jsonEncode(candMap);
            _wsSocket?.add(candMsg);
            _addLog('Sent ICE Candidate via WebSocket.');
          }
        }
      };
    } catch (e) {
      final errDetail = e is SocketException
          ? 'Network timeout or unreachable host (OS Error 121)'
          : e.toString();
      _addLog('WebSocket connection failed: $errDetail');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection Failed: $errDetail')));
    }
  }

  bool _isSignalingDescriptionSent = false;

  Future<void> _requestStreamWebSocket() async {
    if (_wsSocket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect to WebSocket Signaling Server first.'),
        ),
      );
      return;
    }

    try {
      if (_peerConnection == null) await _createPeerConnection();

      final reqMap = <String, dynamic>{'type': 'request'};
      final targetId = _roomId.text.trim();
      if (targetId.isNotEmpty) {
        reqMap['id'] = targetId;
      }
      final reqMsg = jsonEncode(reqMap);
      _wsSocket!.add(reqMsg);
      _addLog('Sent Live Video Stream Request ("$reqMsg") via WebSocket.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Requested live video stream from server!'),
        ),
      );
    } catch (e) {
      _addLog('Error requesting video stream: $e');
    }
  }

  Future<void> _sendOfferWebSocket() async {
    if (_wsSocket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect to WebSocket Signaling Server first.'),
        ),
      );
      return;
    }
    final targetId = _roomId.text.trim();
    if (targetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Target Peer ID (Room ID).')),
      );
      return;
    }

    try {
      _isSignalingDescriptionSent = false;
      if (_peerConnection == null) await _createPeerConnection();

      // Create DataChannel as Offerer with standard in-band negotiation (DCEP)
      final dcInit = RTCDataChannelInit();
      final dc = await _peerConnection!.createDataChannel(
        'datachannel',
        dcInit,
      );
      _setupDataChannel(dc);

      // Create Offer
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      final offerMsg = jsonEncode({
        'id': targetId,
        'type': 'offer',
        'description': offer.sdp,
        'sdp': offer.sdp,
      });

      // Send SDP Offer FIRST over WebSocket
      _wsSocket!.add(offerMsg);
      _isSignalingDescriptionSent = true;
      _addLog('Sent SDP Offer via WebSocket to "$targetId".');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent SDP Offer to "$targetId" over WebSocket!'),
        ),
      );
    } catch (e) {
      _addLog('Error creating/sending offer: $e');
    }
  }

  HttpServer? _builtInServer;
  final Map<String, WebSocket> _serverClients = {};
  bool _isServerRunning = false;

  Future<void> _toggleBuiltInServer() async {
    if (_isServerRunning) {
      await _builtInServer?.close(force: true);
      _builtInServer = null;
      _serverClients.clear();
      setState(() {
        _isServerRunning = false;
      });
      _addLog('Built-in Signaling Server stopped.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signaling Server stopped.')),
      );
    } else {
      try {
        _builtInServer = await HttpServer.bind(InternetAddress.anyIPv4, 8000);
        setState(() {
          _isServerRunning = true;
        });
        _addLog('Built-in Signaling Server running on 0.0.0.0:8000.');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Built-in Signaling Server started on 0.0.0.0:8000!'),
          ),
        );

        _builtInServer!.listen((HttpRequest request) async {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            final pathId = request.uri.path.replaceAll(RegExp(r'^/'), '');
            final socket = await WebSocketTransformer.upgrade(request);
            String clientId = pathId;

            if (clientId.isNotEmpty) {
              _serverClients[clientId] = socket;
              _addLog('Server: Client "$clientId" connected (URL path).');
            }

            socket.listen(
              (data) {
                try {
                  final jsonMap =
                      jsonDecode(data.toString()) as Map<String, dynamic>;
                  final type = jsonMap['type'] as String?;

                  if (type == 'id' &&
                      (jsonMap['id'] as String?)?.isNotEmpty == true) {
                    clientId = jsonMap['id'] as String;
                    _serverClients[clientId] = socket;
                    _addLog('Server: Client "$clientId" registered.');
                    return;
                  }

                  if (clientId.isNotEmpty) {
                    _serverClients[clientId] = socket;
                  }

                  final targetId = jsonMap['id']?.toString();
                  if (targetId != null &&
                      _serverClients.containsKey(targetId)) {
                    // Replace target ID with sender ID when relaying to recipient
                    jsonMap['id'] = clientId;
                    _serverClients[targetId]?.add(jsonEncode(jsonMap));
                    _addLog(
                      'Server: Relayed "$type" from "$clientId" to "$targetId".',
                    );
                  } else if (targetId != null) {
                    _addLog('Server: Target "$targetId" not found.');
                  }
                } catch (e) {
                  _addLog('Server error processing message: $e');
                }
              },
              onDone: () {
                if (clientId.isNotEmpty) {
                  _serverClients.remove(clientId);
                  _addLog('Server: Client "$clientId" disconnected.');
                }
              },
            );
          } else {
            request.response.statusCode = HttpStatus.forbidden;
            request.response.close();
          }
        });
      } catch (e) {
        _addLog('Failed to start Built-in Signaling Server: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start server on port 8000: $e')),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    _stateTimer?.cancel();
    _statsTimer?.cancel();
    _prevAudioPackets = 0;
    _prevVideoPackets = 0;
    _prevAudioBytes = 0;
    _prevVideoBytes = 0;
    _hasRecordedInitialStats = false;
    _allChannels.clear();
    _wsSocket?.close();
    _wsSocket = null;
    await _session.close();
    _peerConnection = null;
    _dataChannel = null;
    _localAnswerCtrl.clear();
    _localCandidatesCtrl.clear();
    ref
        .read(cmWebRtcParamsProvider.notifier)
        .update(
          (s) => s.copyWith(
            isConnected: false,
            localSdpAnswer: '',
            localIceCandidates: '',
          ),
        );
    _addLog('Session disconnected.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final params = ref.watch(cmWebRtcParamsProvider);

    return MyPanel(
      icon: Icons.video_call,
      panelTitle: 'WebRTC Stream & Data (libdatachannel)',
      panelSubtitle:
          'Peer-to-peer WebRTC SDP offer/answer exchange, video stream, and DataChannel for libdatachannel C++ CLI & embedded boards',
      panelActions: [
        StatusBadge(
          label: params.isConnected ? 'CONNECTED' : 'DISCONNECTED',
          color: params.isConnected ? c.primary : c.muted,
        ),
      ],
      children: [
        // Card 1: Mode Selection & Setup
        MyPanelBody(
          icon: Icons.settings_ethernet,
          title: 'Signaling Mode & Peer Configuration',
          subtitle:
              'Select Manual SDP Copy-Paste mode for libdatachannel ./offerer or WebSocket Signaling Server',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Signaling Mode: ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<WebRtcSignalingMode>(
                    segments: const [
                      ButtonSegment(
                        value: WebRtcSignalingMode.manualSdp,
                        label: Text('Manual SDP'),
                        icon: Icon(Icons.copy, size: 16),
                      ),
                      ButtonSegment(
                        value: WebRtcSignalingMode.webSocket,
                        label: Text('WebSocket Server'),
                        icon: Icon(Icons.compare_arrows, size: 16),
                      ),
                      ButtonSegment(
                        value: WebRtcSignalingMode.webBrowser,
                        label: Text('Web Stream Page (http://)'),
                        icon: Icon(Icons.language, size: 16),
                      ),
                    ],
                    selected: {params.mode},
                    onSelectionChanged: (val) {
                      final newState = ref
                          .read(cmWebRtcParamsProvider.notifier)
                          .update((s) => s.copyWith(mode: val.first));
                      _saveWebRtcParamsToHive(newState);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (params.mode != WebRtcSignalingMode.webBrowser)
                    _field(_stunServer, 'STUN Server', width: 280),
                  if (params.mode == WebRtcSignalingMode.webSocket) ...[
                    _field(_signalingUrl, 'WS Signaling URL', width: 240),
                    _field(_roomId, 'Room ID', width: 100),
                    _field(_peerId, 'Peer ID', width: 120),
                  ],
                  if (params.mode == WebRtcSignalingMode.webBrowser) ...[
                    _field(
                      _webUrlCtrl,
                      'Web Stream Page URL (http://...)',
                      width: 340,
                    ),
                    PanelActionButton(
                      icon: Icons.open_in_browser,
                      label: 'Open Web Stream Page',
                      tooltipStr:
                          'Open live WebRTC video stream page in system web browser',
                      onPressed: _openExternalBrowser,
                    ),
                  ],
                  if (params.mode != WebRtcSignalingMode.webBrowser)
                    PanelActionButton(
                      icon: params.isConnected ? Icons.stop : Icons.play_arrow,
                      label: params.isConnected
                          ? 'Disconnect'
                          : (params.mode == WebRtcSignalingMode.webSocket
                                ? 'Connect WS'
                                : 'Reset Session'),
                      tooltipStr: params.mode == WebRtcSignalingMode.webSocket
                          ? 'Connect to WebSocket Signaling Server'
                          : 'Close or reset current WebRTC session',
                      onPressed: params.isConnected
                          ? _disconnect
                          : (params.mode == WebRtcSignalingMode.webSocket
                                ? _connectWebSocketSignaling
                                : _disconnect),
                    ),
                  if (params.mode == WebRtcSignalingMode.webSocket &&
                      _wsSocket != null) ...[
                    PanelActionButton(
                      icon: Icons.play_circle_filled,
                      label: 'Request Stream',
                      tooltipStr:
                          'Request live video stream from server (Viewer mode)',
                      onPressed: _requestStreamWebSocket,
                    ),
                    PanelActionButton(
                      icon: Icons.send,
                      label: 'Send Offer WS',
                      tooltipStr:
                          'Send SDP Offer over WebSocket to target peer ID (Broadcaster mode)',
                      onPressed: _sendOfferWebSocket,
                    ),
                  ],
                  if (params.mode == WebRtcSignalingMode.webSocket) ...[
                    PanelActionButton(
                      icon: _isServerRunning ? Icons.dns_outlined : Icons.dns,
                      label: _isServerRunning
                          ? 'Stop Host Server'
                          : 'Start Host Server (8000)',
                      tooltipStr:
                          'Start/stop embedded WebSocket Signaling Server on 0.0.0.0:8000',
                      onPressed: _toggleBuiltInServer,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Card 2: Manual SDP Exchange (libdatachannel Offerer/Answerer helper)
        if (params.mode == WebRtcSignalingMode.manualSdp)
          MyPanelBody(
            icon: Icons.sync_alt,
            title: 'Manual SDP & Candidate Exchange (libdatachannel CLI)',
            subtitle:
                'Paste Local Description & Candidates from ./offerer, then copy Local Answer back to ./offerer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Step 1 & 2 Input Remote Offer & Candidates
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Step 1: Paste "Local Description" (SDP Offer) from ./offerer',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _remoteSdpCtrl,
                            maxLines: 5,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                            decoration: const InputDecoration(
                              hintText: 'v=0\no=rtc...\na=ice-ufrag...',
                              isDense: true,
                              contentPadding: EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Step 2: Paste "Local Candidate" lines from ./offerer',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _remoteCandidatesCtrl,
                            maxLines: 3,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                            decoration: const InputDecoration(
                              hintText:
                                  'a=candidate:1 1 UDP ...\na=candidate:2 1 UDP ...',
                              isDense: true,
                              contentPadding: EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.bolt, size: 16),
                                label: const Text(
                                  'Parse Offer & Create Answer',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: c.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _processManualOffer,
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Candidates Only'),
                                onPressed: _addRemoteCandidatesManually,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right Column: Step 3 & 4 Copy Local Answer & Candidates back to ./offerer
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Step 3: Copy Generated "Local Answer SDP"',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16),
                                tooltip: 'Copy Answer SDP',
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: _localAnswerCtrl.text),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Answer SDP copied to clipboard!',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          TextField(
                            controller: _localAnswerCtrl,
                            maxLines: 5,
                            readOnly: true,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                            decoration: const InputDecoration(
                              hintText:
                                  'Generated SDP Answer will appear here...',
                              isDense: true,
                              contentPadding: EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: c.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: c.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: c.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'In ./offerer terminal, type 1 and press Enter, then paste Step 3 and press Enter. You should see [State: connected] and [Data channel "datachannel": open].',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: c.foreground,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Card 3: Live Video Viewport
        MyPanelBody(
          icon: Icons.videocam,
          title: 'Live Camera / Video Viewport',
          subtitle:
              'Hardware-accelerated RTCVideoView for incoming H.264/VP8 video streams',
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
                        label: Text(
                          'Video Track: ${params.enableVideo ? "ON" : "OFF"}',
                        ),
                        selected: params.enableVideo,
                        onSelected: _toggleVideoTrack,
                      ),
                      FilterChip(
                        label: Text(
                          'Audio Track: ${params.enableAudio ? "ON" : "OFF"}',
                        ),
                        selected: params.enableAudio,
                        onSelected: _toggleAudioTrack,
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
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
                            final newState = ref
                                .read(cmWebRtcParamsProvider.notifier)
                                .update((s) => s.copyWith(preferredCodec: val));
                            _saveWebRtcParamsToHive(newState);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Height: ',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                      for (final h in [240.0, 360.0, 480.0, 720.0])
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () {
                            final newState = ref
                                .read(cmWebRtcParamsProvider.notifier)
                                .update((s) => s.copyWith(viewportHeight: h));
                            _saveWebRtcParamsToHive(newState);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: params.viewportHeight == h
                                  ? c.primary.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: params.viewportHeight == h
                                    ? c.primary
                                    : c.border,
                              ),
                            ),
                            child: Text(
                              '${h.toInt()}p',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: params.viewportHeight == h
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: params.viewportHeight == h
                                    ? c.primary
                                    : c.foreground,
                              ),
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.fullscreen, size: 20),
                        tooltip: 'Fullscreen Video Dialog',
                        onPressed: _showFullscreenVideo,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: params.viewportHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border.all(color: c.border),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: params.mode == WebRtcSignalingMode.webBrowser
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.language,
                                size: 48,
                                color: Colors.white54,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _webUrlCtrl.text.trim().isEmpty
                                    ? 'http://192.168.1.7:8080/'
                                    : _webUrlCtrl.text.trim(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.open_in_browser,
                                  size: 18,
                                ),
                                label: const Text('Open Web Stream Page'),
                                onPressed: _openExternalBrowser,
                              ),
                            ],
                          ),
                        )
                      : (!params.enableVideo
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.videocam_off,
                                      size: 48,
                                      color: Colors.white38,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Video Track OFF (Muted)',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Toggle "Video Track: ON" above to resume video feed',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : (_remoteRenderer.srcObject != null
                                  ? RTCVideoView(
                                      _remoteRenderer,
                                      objectFit: RTCVideoViewObjectFit
                                          .RTCVideoViewObjectFitContain,
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            params.isConnected
                                                ? Icons.videocam
                                                : Icons.video_camera_front,
                                            size: 48,
                                            color: params.isConnected
                                                ? c.primary
                                                : Colors.white38,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            params.isConnected
                                                ? 'WebRTC Media Connection Active (DataChannel Only / Waiting for Video Track)'
                                                : 'Camera Stream Disconnected',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))),
                ),
              ),
              // Draggable Resize Handle
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (details) {
                  final newHeight = (params.viewportHeight + details.delta.dy)
                      .clamp(180.0, 960.0);
                  ref
                      .read(cmWebRtcParamsProvider.notifier)
                      .update((s) => s.copyWith(viewportHeight: newHeight));
                },
                onVerticalDragEnd: (_) {
                  _saveWebRtcParamsToHive(ref.read(cmWebRtcParamsProvider));
                },
                onDoubleTap: () {
                  final next = params.viewportHeight == 360.0 ? 560.0 : 360.0;
                  final newState = ref
                      .read(cmWebRtcParamsProvider.notifier)
                      .update((s) => s.copyWith(viewportHeight: next));
                  _saveWebRtcParamsToHive(newState);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeUpDown,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: c.surface.withValues(alpha: 0.6),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: Border(
                        left: BorderSide(color: c.border),
                        right: BorderSide(color: c.border),
                        bottom: BorderSide(color: c.border),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.drag_handle, size: 16, color: c.muted),
                          const SizedBox(width: 6),
                          Text(
                            '${params.viewportHeight.round()}px (Drag to resize height)',
                            style: TextStyle(
                              fontSize: 10,
                              color: c.muted,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Card 4: DataChannel & Event Logs
        MyPanelBody(
          icon: Icons.swap_calls,
          title: 'DataChannel Control & Session Logs',
          subtitle:
              'Send & receive strings over SCTP DataChannel and view real-time ICE / DTLS handshake logs',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable WebRTC DataChannel (PTY/Telemetry)'),
                subtitle: const Text(
                  'Exchanges raw commands and stats over SCTP DataChannel',
                ),
                value: params.enableDataChannel,
                onChanged: (val) {
                  ref
                      .read(cmWebRtcParamsProvider.notifier)
                      .update((s) => s.copyWith(enableDataChannel: val));
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Binary Header Protocol (Envelope: 0x01 Array / 0x02 File)',
                ),
                subtitle: const Text(
                  'Uses 0x01 (Byte Array), 0x02 (File Start), 0x03 (File Chunk), 0x04 (File End) headers to distinguish array vs file',
                ),
                value: params.useBinaryHeaderEnvelope,
                onChanged: (val) {
                  final newState = ref
                      .read(cmWebRtcParamsProvider.notifier)
                      .update((s) => s.copyWith(useBinaryHeaderEnvelope: val));
                  _saveWebRtcParamsToHive(newState);
                },
              ),
              const SizedBox(height: 8),
              // DataChannel Live Status & Reopen Action
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _safeDataChannelState ==
                              RTCDataChannelState.RTCDataChannelOpen
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            _safeDataChannelState ==
                                RTCDataChannelState.RTCDataChannelOpen
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _safeDataChannelState ==
                                  RTCDataChannelState.RTCDataChannelOpen
                              ? Icons.check_circle
                              : Icons.sync_problem,
                          size: 14,
                          color:
                              _safeDataChannelState ==
                                  RTCDataChannelState.RTCDataChannelOpen
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'DataChannel: ${_safeDataChannelState?.name ?? 'Closed'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color:
                                _safeDataChannelState ==
                                    RTCDataChannelState.RTCDataChannelOpen
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_safeDataChannelState !=
                      RTCDataChannelState.RTCDataChannelOpen)
                    PanelActionButton(
                      icon: Icons.refresh,
                      label: 'Reopen Channel',
                      tooltipStr:
                          'Re-create and open a new DataChannel on the active PeerConnection',
                      onPressed: _reopenDataChannel,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Text Message Input Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _field(_dataMessage, 'Text Message (String)', width: 320),
                  PanelActionButton(
                    icon: Icons.send,
                    label: 'Send Text',
                    tooltipStr: 'Send text string over WebRTC DataChannel',
                    onPressed: _sendDataMessage,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Byte Array Input Row & Presets Menu
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _field(
                    _byteInputCtrl,
                    'Byte Array (Hex: 01 02 AA FF / 0x01, 0x02)',
                    width: 320,
                  ),
                  PanelActionButton(
                    icon: Icons.data_array,
                    label: 'Send Byte Array',
                    tooltipStr:
                        'Send binary byte array (Uint8List) over WebRTC DataChannel',
                    onPressed: _sendByteArray,
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Byte Array Presets',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(4),
                        color: c.surface,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.list_alt, size: 16, color: c.foreground),
                          const SizedBox(width: 4),
                          Text(
                            'Byte Presets',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: c.foreground,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                    onSelected: (presetVal) {
                      setState(() {
                        _byteInputCtrl.text = presetVal;
                      });
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: '01 00 00 00',
                        child: Text('Ping Packet: 01 00 00 00 (4 bytes)'),
                      ),
                      PopupMenuItem(
                        value: 'AA BB CC DD EE FF 00 11',
                        child: Text(
                          'Sync Header: AA BB CC DD EE FF 00 11 (8 bytes)',
                        ),
                      ),
                      PopupMenuItem(
                        value:
                            '00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F',
                        child: Text('Sequential 16-Bytes: 00..0F'),
                      ),
                      PopupMenuItem(
                        value:
                            'FF FF FF FF 55 55 55 55 AA AA AA AA 00 00 00 00',
                        child: Text('Bit Patterns: FF/55/AA/00 (16 bytes)'),
                      ),
                      PopupMenuItem(
                        value: '48 65 6C 6C 6F 20 57 65 62 52 54 43 21',
                        child: Text('ASCII "Hello WebRTC!" in Hex (13 bytes)'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // File Transfer Row & Menu
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _field(
                    _fileInfoCtrl,
                    'Selected File (Click "Open File" to pick)',
                    width: 320,
                  ),
                  PanelActionButton(
                    icon: Icons.folder_open,
                    label: 'Open File',
                    tooltipStr:
                        'Open file picker to select a file for DataChannel transfer',
                    onPressed: () => _pickFile(),
                  ),
                  PanelActionButton(
                    icon: _isSendingFile
                        ? Icons.hourglass_top
                        : Icons.file_upload,
                    label: _isSendingFile ? 'Sending…' : 'Send File',
                    tooltipStr:
                        'Send selected file over WebRTC DataChannel (chunked binary)',
                    onPressed: _isSendingFile ? null : () => _sendFile(),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'File Transfer Options',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(4),
                        color: c.surface,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.more_horiz, size: 16, color: c.foreground),
                          const SizedBox(width: 4),
                          Text(
                            'File Menu',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: c.foreground,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                    onSelected: (option) {
                      if (option == 'single_named') {
                        _sendFile(mode: 'single_named');
                      } else if (option == 'single_unnamed') {
                        _sendFile(mode: 'single_unnamed');
                      } else if (option == 'raw') {
                        _sendFile(mode: 'raw');
                      } else if (option == 'chunked_02') {
                        _sendFile(mode: 'chunked_02', chunkSize: 16384);
                      } else if (option == 'multi_chunked') {
                        _sendFile(mode: 'multi_chunked', chunkSize: 16384);
                      } else if (option == 'loadHex') {
                        _pickFile(loadToHexField: true);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'single_named',
                        child: Text(
                          'Send [0x02 + Filename + Data] (Default / Embedded File)',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'single_unnamed',
                        child: Text('Send [0x02 + Data] (Single Payload)'),
                      ),
                      PopupMenuItem(
                        value: 'raw',
                        child: Text('Send Raw Binary File (No Header)'),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'chunked_02',
                        child: Text(
                          'Send Chunked (16 KB Chunks with 0x02 Header)',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'multi_chunked',
                        child: Text(
                          'Send Multi-Phase (0x02 Start / 0x03 Chunks / 0x04 End)',
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'loadHex',
                        child: Text('Open File & Load into Hex Field'),
                      ),
                    ],
                  ),
                ],
              ),
              if (_isSendingFile) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _fileSendProgress > 0
                              ? _fileSendProgress
                              : null,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(_fileSendProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: c.muted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Session Logs:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        tooltip: 'Copy Session Logs',
                        onPressed: _logs.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(
                                  ClipboardData(text: _logs.join('\n')),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Session logs copied to clipboard!',
                                    ),
                                  ),
                                );
                              },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        tooltip: 'Clear Session Logs',
                        onPressed: () {
                          setState(() {
                            _logs.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: c.border),
                ),
                child: SelectionArea(
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, idx) {
                      return SelectableText(
                        _logs[idx],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.greenAccent,
                        ),
                      );
                    },
                  ),
                ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}
