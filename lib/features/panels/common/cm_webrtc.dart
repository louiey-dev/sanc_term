import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
    );
  }
}

/// Riverpod provider for persisting WebRTC parameter values across panel navigation and app restarts
final cmWebRtcParamsProvider = StateProvider<CmWebRtcParamsState>(
  (ref) => _loadWebRtcParamsFromHive(),
);

class CmWebRtcPanel extends ConsumerStatefulWidget {
  const CmWebRtcPanel({super.key});

  @override
  ConsumerState<CmWebRtcPanel> createState() => _CmWebRtcPanelState();
}

class _CmWebRtcPanelState extends ConsumerState<CmWebRtcPanel> {
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

  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
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
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening web browser: $e')),
      );
    }
  }

  Future<void> _initVideoRenderer() async {
    await _remoteRenderer.initialize();
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
    _webUrlCtrl.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _peerConnection?.dispose();
    _signalingUrl.dispose();
    _roomId.dispose();
    _peerId.dispose();
    _stunServer.dispose();
    _remoteSdpCtrl.dispose();
    _remoteCandidatesCtrl.dispose();
    _localAnswerCtrl.dispose();
    _localCandidatesCtrl.dispose();
    _dataMessage.dispose();
    super.dispose();
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

    _peerConnection = await createPeerConnection(configuration, constraints);

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

    _peerConnection!.onTrack = (event) {
      _addLog('Track received: ${event.track.kind}');
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
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
              _dataChannel = channel;
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

    // Only set as primary _dataChannel if none exists or if this channel is open
    if (_dataChannel == null ||
        channel.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannel = channel;
    }

    channel.onDataChannelState = (state) {
      _addLog('DataChannel "${channel.label}" State changed to: ${state.name}');
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _dataChannel = channel;
        _addLog(
          'Active DataChannel set to "${channel.label}". Ready for messaging!',
        );
      }
      _updateConnectionState();
    };

    channel.onMessage = (data) {
      _addLog('Received Data [${channel.label}]: ${data.text}');
    };

    if (channel.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannel = channel;
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
      final answer = await _peerConnection!.createAnswer();
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

  void _sendDataMessage() {
    final text = _dataMessage.text.trim();
    if (text.isEmpty) return;

    final state = _safeDataChannelState;
    if (_dataChannel != null && state == RTCDataChannelState.RTCDataChannelOpen) {
      try {
        _dataChannel!.send(RTCDataChannelMessage(text));
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
                _peerConnection = null;
                await _createPeerConnection();

                // Auto-sync target Room ID in UI to sender ID
                _roomId.text = senderId;

                // Normalize line endings to CRLF (\r\n) without stripping candidate lines
                final normalizedSdp =
                    '${sdp.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).join('\r\n')}\r\n';

                final offer = RTCSessionDescription(normalizedSdp, 'offer');
                await _peerConnection!.setRemoteDescription(offer);

                final answer = await _peerConnection!.createAnswer();
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

                final answerMsg = jsonEncode({
                  'id': senderId,
                  'type': 'answer',
                  'description': fullAnswerSdp,
                  'sdp': fullAnswerSdp,
                });
                _wsSocket!.add(answerMsg);
                _isSignalingDescriptionSent = true;
                _addLog('Sent SDP Answer via WebSocket to "$senderId".');
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
          if (activeTargetId.isNotEmpty &&
              _wsSocket != null &&
              _isSignalingDescriptionSent) {
            final candMsg = jsonEncode({
              'id': activeTargetId,
              'type': 'candidate',
              'candidate': candLine,
              'mid': candidate.sdpMid ?? '0',
            });
            _wsSocket?.add(candMsg);
            _addLog('Sent ICE Candidate via WebSocket to "$activeTargetId".');
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

  void _disconnect() {
    _stateTimer?.cancel();
    _allChannels.clear();
    _wsSocket?.close();
    _wsSocket = null;
    _peerConnection?.close();
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
                    _field(_webUrlCtrl, 'Web Stream Page URL (http://...)', width: 340),
                    PanelActionButton(
                      icon: Icons.open_in_browser,
                      label: 'Open Web Stream Page',
                      tooltipStr: 'Open live WebRTC video stream page in system web browser',
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
                      icon: Icons.send,
                      label: 'Send Offer WS',
                      tooltipStr:
                          'Send SDP Offer over WebSocket to target peer ID',
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
                        onSelected: (val) {
                          ref
                              .read(cmWebRtcParamsProvider.notifier)
                              .update((s) => s.copyWith(enableVideo: val));
                        },
                      ),
                      FilterChip(
                        label: Text(
                          'Audio Track: ${params.enableAudio ? "ON" : "OFF"}',
                        ),
                        selected: params.enableAudio,
                        onSelected: (val) {
                          ref
                              .read(cmWebRtcParamsProvider.notifier)
                              .update((s) => s.copyWith(enableAudio: val));
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
                            final newState = ref
                                .read(cmWebRtcParamsProvider.notifier)
                                .update((s) => s.copyWith(preferredCodec: val));
                            _saveWebRtcParamsToHive(newState);
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: params.mode == WebRtcSignalingMode.webBrowser
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language, size: 48, color: Colors.white54),
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
                                icon: const Icon(Icons.open_in_browser, size: 18),
                                label: const Text('Open Web Stream Page'),
                                onPressed: _openExternalBrowser,
                              ),
                            ],
                          ),
                        )
                      : (_remoteRenderer.srcObject != null
                          ? RTCVideoView(_remoteRenderer)
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
                            )),
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _field(
                    _dataMessage,
                    'Test message to libdatachannel peer',
                    width: 340,
                  ),
                  PanelActionButton(
                    icon: Icons.send,
                    label: 'Send Message',
                    tooltipStr: 'Send string over WebRTC DataChannel',
                    onPressed: _sendDataMessage,
                  ),
                ],
              ),
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
