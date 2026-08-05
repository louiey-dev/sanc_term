import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

enum StreamPlayMode { mjpegStream, snapshotPolling, testPattern }

/// State model for preserving UVC Stream panel parameters across page transitions
class UvcStreamParamsState {
  final String streamUrl;
  final StreamPlayMode playMode;
  final String resWidth;
  final String resHeight;
  final String fps;
  final String brightness;
  final String contrast;
  final String saturation;
  final String gain;
  final String exposure;
  final String streamPort;
  final String customCmd;

  const UvcStreamParamsState({
    this.streamUrl = 'http://192.168.1.100:8080/mjpeg',
    this.playMode = StreamPlayMode.mjpegStream,
    this.resWidth = '1920',
    this.resHeight = '1080',
    this.fps = '30',
    this.brightness = '128',
    this.contrast = '128',
    this.saturation = '128',
    this.gain = '64',
    this.exposure = '156',
    this.streamPort = '8080',
    this.customCmd = 'status',
  });

  UvcStreamParamsState copyWith({
    String? streamUrl,
    StreamPlayMode? playMode,
    String? resWidth,
    String? resHeight,
    String? fps,
    String? brightness,
    String? contrast,
    String? saturation,
    String? gain,
    String? exposure,
    String? streamPort,
    String? customCmd,
  }) {
    return UvcStreamParamsState(
      streamUrl: streamUrl ?? this.streamUrl,
      playMode: playMode ?? this.playMode,
      resWidth: resWidth ?? this.resWidth,
      resHeight: resHeight ?? this.resHeight,
      fps: fps ?? this.fps,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      gain: gain ?? this.gain,
      exposure: exposure ?? this.exposure,
      streamPort: streamPort ?? this.streamPort,
      customCmd: customCmd ?? this.customCmd,
    );
  }
}

/// Riverpod provider for persisting UVC Stream panel parameter values
final uvcStreamParamsProvider = StateProvider<UvcStreamParamsState>(
  (ref) => const UvcStreamParamsState(),
);

/// CUSTOMS — UVC Streaming Player & V4L2 Camera Control Panel
class UvcStreamPanel extends ConsumerStatefulWidget {
  final bool standalone;

  const UvcStreamPanel({super.key, this.standalone = true});

  @override
  ConsumerState<UvcStreamPanel> createState() => _UvcStreamPanelState();
}

class _UvcStreamPanelState extends ConsumerState<UvcStreamPanel> {
  // Streaming Player Controllers & State
  late final TextEditingController _streamUrlCtrl;
  StreamPlayMode _playMode = StreamPlayMode.mjpegStream;
  bool _isStreaming = false;
  bool _isConnecting = false;
  String? _streamError;
  Uint8List? _currentFrame;
  int _frameCount = 0;
  double _currentFps = 0.0;
  DateTime? _lastFrameTime;
  Timer? _fpsTimer;
  Timer? _snapshotTimer;
  _MjpegDecoder? _mjpegDecoder;

  // Video Resolution & Framerate Controllers
  late final TextEditingController _resWidthCtrl;
  late final TextEditingController _resHeightCtrl;
  late final TextEditingController _fpsCtrl;

  // Camera Picture Adjustment Controllers
  late final TextEditingController _brightnessCtrl;
  late final TextEditingController _contrastCtrl;
  late final TextEditingController _saturationCtrl;
  late final TextEditingController _gainCtrl;
  late final TextEditingController _exposureCtrl;

  // Streaming Server Controllers
  late final TextEditingController _streamPortCtrl;
  late final TextEditingController _customCmdCtrl;

  @override
  void initState() {
    super.initState();
    _mjpegDecoder = _MjpegDecoder();

    final saved = ref.read(uvcStreamParamsProvider);
    _streamUrlCtrl = TextEditingController(text: saved.streamUrl);
    _playMode = saved.playMode;
    _resWidthCtrl = TextEditingController(text: saved.resWidth);
    _resHeightCtrl = TextEditingController(text: saved.resHeight);
    _fpsCtrl = TextEditingController(text: saved.fps);
    _brightnessCtrl = TextEditingController(text: saved.brightness);
    _contrastCtrl = TextEditingController(text: saved.contrast);
    _saturationCtrl = TextEditingController(text: saved.saturation);
    _gainCtrl = TextEditingController(text: saved.gain);
    _exposureCtrl = TextEditingController(text: saved.exposure);
    _streamPortCtrl = TextEditingController(text: saved.streamPort);
    _customCmdCtrl = TextEditingController(text: saved.customCmd);

    _streamUrlCtrl.addListener(_saveParams);
    _resWidthCtrl.addListener(_saveParams);
    _resHeightCtrl.addListener(_saveParams);
    _fpsCtrl.addListener(_saveParams);
    _brightnessCtrl.addListener(_saveParams);
    _contrastCtrl.addListener(_saveParams);
    _saturationCtrl.addListener(_saveParams);
    _gainCtrl.addListener(_saveParams);
    _exposureCtrl.addListener(_saveParams);
    _streamPortCtrl.addListener(_saveParams);
    _customCmdCtrl.addListener(_saveParams);
  }

  void _saveParams() {
    ref.read(uvcStreamParamsProvider.notifier).state = UvcStreamParamsState(
      streamUrl: _streamUrlCtrl.text,
      playMode: _playMode,
      resWidth: _resWidthCtrl.text,
      resHeight: _resHeightCtrl.text,
      fps: _fpsCtrl.text,
      brightness: _brightnessCtrl.text,
      contrast: _contrastCtrl.text,
      saturation: _saturationCtrl.text,
      gain: _gainCtrl.text,
      exposure: _exposureCtrl.text,
      streamPort: _streamPortCtrl.text,
      customCmd: _customCmdCtrl.text,
    );
  }

  @override
  void dispose() {
    _stopPlayer(isDisposing: true);
    _streamUrlCtrl.dispose();
    _resWidthCtrl.dispose();
    _resHeightCtrl.dispose();
    _fpsCtrl.dispose();
    _brightnessCtrl.dispose();
    _contrastCtrl.dispose();
    _saturationCtrl.dispose();
    _gainCtrl.dispose();
    _exposureCtrl.dispose();
    _streamPortCtrl.dispose();
    _customCmdCtrl.dispose();
    super.dispose();
  }

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  // ---------------------------------------------------------------------------
  // Player Controls & Stream Decoder Logic
  // ---------------------------------------------------------------------------
  void _startPlayer() {
    final url = _streamUrlCtrl.text.trim();
    if (url.isEmpty && _playMode != StreamPlayMode.testPattern) return;

    setState(() {
      _isStreaming = true;
      _isConnecting = true;
      _streamError = null;
      _frameCount = 0;
      _currentFps = 0.0;
    });

    _lastFrameTime = DateTime.now();
    _fpsTimer?.cancel();
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentFps = _frameCount.toDouble();
          _frameCount = 0;
        });
      }
    });

    if (_playMode == StreamPlayMode.mjpegStream) {
      _mjpegDecoder?.start(
        url,
        onFrame: (bytes) {
          if (mounted) {
            setState(() {
              _currentFrame = bytes;
              _isConnecting = false;
              _frameCount++;
            });
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _streamError = err;
              _isConnecting = false;
              _isStreaming = false;
            });
          }
        },
      );
    } else if (_playMode == StreamPlayMode.snapshotPolling) {
      _startSnapshotPolling(url);
    } else {
      // Test Pattern mode
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _stopPlayer({bool isDisposing = false}) {
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
    _fpsTimer?.cancel();
    _fpsTimer = null;
    _mjpegDecoder?.stop();

    _isStreaming = false;
    _isConnecting = false;
    _currentFps = 0.0;

    if (!isDisposing && mounted) {
      setState(() {});
    }
  }

  void _startSnapshotPolling(String url) {
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer.periodic(const Duration(milliseconds: 330), (
      _,
    ) async {
      if (!_isStreaming || !mounted) return;
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 2);
        final req = await client.getUrl(
          Uri.parse('$url?t=${DateTime.now().millisecondsSinceEpoch}'),
        );
        final resp = await req.close();
        if (resp.statusCode == 200) {
          final bytes = await resp.fold<List<int>>(
            <int>[],
            (acc, chunk) => acc..addAll(chunk),
          );
          if (mounted) {
            setState(() {
              _currentFrame = Uint8List.fromList(bytes);
              _isConnecting = false;
              _frameCount++;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _streamError = 'HTTP ${resp.statusCode}';
              _isConnecting = false;
            });
          }
        }
        client.close();
      } catch (e) {
        if (mounted) {
          setState(() {
            _streamError = e.toString();
            _isConnecting = false;
          });
        }
      }
    });
  }

  PanelActionButton _btn(
    String label,
    String cmd,
    String tip, [
    IconData? icon,
  ]) => PanelActionButton(
    icon: icon ?? Icons.videocam,
    label: label,
    tooltipStr: tip,
    onPressed: () => _send(cmd),
  );

  Widget _inputField(
    TextEditingController controller,
    String label, {
    double width = 110,
    String? hint,
  }) {
    return SizedBox(
      width: width,
      height: 36,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.colors.primary,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bodies = _buildPanelBodies();
    if (widget.standalone) {
      return MyPanel(
        icon: Icons.videocam,
        panelTitle: 'UVC Streaming Player Panel',
        panelSubtitle:
            'USB Video Class (UVC) camera live stream viewer & V4L2 controls',
        panelActions: const [],
        children: bodies,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < bodies.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          bodies[i],
        ],
      ],
    );
  }

  List<Widget> _buildPanelBodies() {
    return [
      // 0. Live Video Stream Player (Preview Viewport)
      MyPanelBody(
        icon: Icons.play_circle_fill,
        title: 'CUSTOMS — Live Video Stream Player',
        subtitle:
            'Embedded live MJPEG / HTTP camera viewer & stream inspector',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stream URL Bar & Control Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  height: 36,
                  child: TextField(
                    controller: _streamUrlCtrl,
                    style: const TextStyle(
                      fontFamily: 'Consolas',
                      fontSize: 12,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Stream URL (HTTP / MJPEG)',
                      hintText: 'http://<ip>:8080/mjpeg',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: DropdownButton<StreamPlayMode>(
                    value: _playMode,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    underline: Container(),
                    onChanged: (mode) {
                      if (mode != null) {
                        setState(() => _playMode = mode);
                        _saveParams();
                        if (_isStreaming) {
                          _stopPlayer();
                          _startPlayer();
                        }
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: StreamPlayMode.mjpegStream,
                        child: Text('Live MJPEG Stream'),
                      ),
                      DropdownMenuItem(
                        value: StreamPlayMode.snapshotPolling,
                        child: Text('Snapshot Polling (~3 FPS)'),
                      ),
                      DropdownMenuItem(
                        value: StreamPlayMode.testPattern,
                        child: Text('Test Pattern'),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
                  label: Text(_isStreaming ? 'Stop Player' : 'Play Stream'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isStreaming
                            ? Colors.red.shade700
                            : context.colors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(110, 36),
                  ),
                  onPressed: () {
                    if (_isStreaming) {
                      _stopPlayer();
                    } else {
                      _startPlayer();
                    }
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reload'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 36),
                  ),
                  onPressed: () {
                    _stopPlayer();
                    _startPlayer();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Camera Stream Screen Viewport
            Container(
              width: double.infinity,
              height: 340,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _isStreaming
                          ? context.colors.primary.withOpacity(0.6)
                          : Colors.grey.shade800,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Video Frame Render Area
                  Center(
                    child:
                        _playMode == StreamPlayMode.testPattern
                            ? _buildTestPattern()
                            : _currentFrame != null
                            ? Image.memory(
                              _currentFrame!,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              errorBuilder: (ctx, err, stack) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.broken_image,
                                      color: Colors.orangeAccent,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error rendering frame: $err',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                            : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isConnecting
                                      ? Icons.sync
                                      : Icons.videocam_off,
                                  color:
                                      _isConnecting
                                          ? context.colors.primary
                                          : Colors.grey,
                                  size: 54,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _isConnecting
                                      ? 'Connecting to stream server...'
                                      : _streamError != null
                                      ? 'Stream Error: $_streamError'
                                      : 'No active video stream. Press "Play Stream" above.',
                                  style: TextStyle(
                                    color:
                                        _streamError != null
                                            ? Colors.redAccent
                                            : Colors.grey.shade300,
                                    fontSize: 13,
                                    fontFamily: 'Consolas',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                  ),

                  // HUD Overlay Top-Left: LIVE Badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _isStreaming
                                ? Colors.red.shade900.withOpacity(0.85)
                                : Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _isStreaming ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _isStreaming
                                      ? Colors.redAccent
                                      : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isStreaming ? 'LIVE' : 'OFFLINE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // HUD Overlay Top-Right: Stats (FPS & Resolution)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _isStreaming
                            ? '${_currentFps.toStringAsFixed(1)} FPS | ${_resWidthCtrl.text}x${_resHeightCtrl.text}'
                            : 'UVC Player',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontFamily: 'Consolas',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 1. Device Discovery & Hardware Status
      MyPanelBody(
        icon: Icons.search,
        title: 'CUSTOMS — UVC Device Discovery & Hardware Status',
        subtitle:
            'USB Video Class device enumeration, V4L2 caps & Linux driver status',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Camera Enumeration & V4L2 Info'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'List Devices',
                  'v4l2-ctl --list-devices || ls -l /dev/video*',
                  'List all V4L2 video capture devices',
                  Icons.format_list_bulleted,
                ),
                _btn(
                  'Video0 Query',
                  'v4l2-ctl -d /dev/video0 --all',
                  'Print detailed capabilities & driver info for /dev/video0',
                  Icons.info_outline,
                ),
                _btn(
                  'Supported Formats',
                  'v4l2-ctl -d /dev/video0 --list-formats-ext',
                  'List pixel formats, resolutions & frame rates for video0',
                  Icons.grid_on,
                ),
                _btn(
                  'USB Bus Info',
                  'lsusb -t 2>/dev/null || lsusb',
                  'Print USB tree and bandwidth negotiation status',
                  Icons.usb,
                ),
                _btn(
                  'UVC Driver Logs',
                  'dmesg | grep -i uvcvideo | tail -n 20',
                  'Show kernel uvcvideo driver kernel messages',
                  Icons.receipt_long,
                ),
              ],
            ),
          ],
        ),
      ),

      // 2. Video Stream & Pipeline Control
      MyPanelBody(
        icon: Icons.videocam,
        title: 'CUSTOMS — UVC Video Stream & Format Control',
        subtitle:
            'Start/Stop streaming pipeline, pixel formats & frame capture',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('UVC Stream Controls'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Stream Start',
                  'uvc_stream start',
                  'Start UVC video stream pipeline',
                  Icons.play_arrow,
                ),
                _btn(
                  'Stream Stop',
                  'uvc_stream stop',
                  'Stop UVC video stream pipeline',
                  Icons.stop,
                ),
                _btn(
                  'MJPEG Format',
                  'v4l2-ctl -d /dev/video0 --set-fmt-video=pixelformat=MJPG',
                  'Set camera output pixel format to Motion JPEG',
                  Icons.image,
                ),
                _btn(
                  'YUYV Format',
                  'v4l2-ctl -d /dev/video0 --set-fmt-video=pixelformat=YUYV',
                  'Set camera output format to uncompressed YUYV (YUV 4:2:2)',
                  Icons.raw_on,
                ),
                _btn(
                  'H.264 Format',
                  'v4l2-ctl -d /dev/video0 --set-fmt-video=pixelformat=H264',
                  'Set camera output format to compressed H.264 video',
                  Icons.video_file,
                ),
                _btn(
                  'Snapshot',
                  'uvc_stream snapshot',
                  'Capture single JPEG snapshot frame from camera',
                  Icons.camera_alt,
                ),
              ],
            ),
          ],
        ),
      ),

      // 3. Resolution & Framerate Config
      MyPanelBody(
        icon: Icons.aspect_ratio,
        title: 'CUSTOMS — Resolution & Frame Rate Configuration',
        subtitle: 'Configure camera stream dimensions and target FPS',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Resolution Settings'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_resWidthCtrl, 'Width', width: 90, hint: '1920'),
                const Text('x', style: TextStyle(fontWeight: FontWeight.bold)),
                _inputField(_resHeightCtrl, 'Height', width: 90, hint: '1080'),
                PanelActionButton(
                  icon: Icons.check,
                  label: 'Set Resolution',
                  tooltipStr: 'Set camera resolution (w x h)',
                  onPressed: () {
                    final w = _resWidthCtrl.text.trim();
                    final h = _resHeightCtrl.text.trim();
                    if (w.isNotEmpty && h.isNotEmpty) {
                      _send(
                        'v4l2-ctl -d /dev/video0 --set-fmt-video=width=$w,height=$h',
                      );
                    }
                  },
                ),
                _btn(
                  '1080p',
                  'uvc_stream res 1920x1080',
                  'Set 1920x1080 Full HD',
                  Icons.hd,
                ),
                _btn(
                  '720p',
                  'uvc_stream res 1280x720',
                  'Set 1280x720 HD',
                  Icons.sd,
                ),
                _btn(
                  'VGA',
                  'uvc_stream res 640x480',
                  'Set 640x480 VGA',
                  Icons.crop_original,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Frame Rate (FPS) Settings'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_fpsCtrl, 'Target FPS', width: 110, hint: '30'),
                PanelActionButton(
                  icon: Icons.speed,
                  label: 'Set FPS',
                  tooltipStr: 'Set camera frame rate',
                  onPressed: () {
                    final fps = _fpsCtrl.text.trim();
                    if (fps.isNotEmpty) {
                      _send('v4l2-ctl -d /dev/video0 --set-parm=$fps');
                    }
                  },
                ),
                _btn(
                  '60 FPS',
                  'uvc_stream fps 60',
                  'Set 60 FPS high frame rate',
                  Icons.speed,
                ),
                _btn(
                  '30 FPS',
                  'uvc_stream fps 30',
                  'Set 30 FPS standard frame rate',
                  Icons.speed,
                ),
                _btn(
                  '15 FPS',
                  'uvc_stream fps 15',
                  'Set 15 FPS low bandwidth frame rate',
                  Icons.speed,
                ),
              ],
            ),
          ],
        ),
      ),

      // 4. Camera Picture & Sensor Control
      MyPanelBody(
        icon: Icons.tune,
        title: 'CUSTOMS — Camera Controls & Picture Adjustments',
        subtitle:
            'Exposure, gain, white balance, brightness & image sensor controls',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Auto Modes'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Auto Exp ON',
                  'v4l2-ctl -d /dev/video0 --set-ctrl=auto_exposure=3',
                  'Enable automatic exposure control mode',
                  Icons.exposure,
                ),
                _btn(
                  'Auto Exp OFF',
                  'v4l2-ctl -d /dev/video0 --set-ctrl=auto_exposure=1',
                  'Disable auto exposure (manual mode)',
                  Icons.exposure_zero,
                ),
                _btn(
                  'Auto WB ON',
                  'v4l2-ctl -d /dev/video0 --set-ctrl=white_balance_automatic=1',
                  'Enable automatic white balance mode',
                  Icons.wb_auto,
                ),
                _btn(
                  'Auto WB OFF',
                  'v4l2-ctl -d /dev/video0 --set-ctrl=white_balance_automatic=0',
                  'Disable auto white balance (manual mode)',
                  Icons.wb_incandescent,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Manual Image Adjustments'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _brightnessCtrl,
                  'Brightness',
                  width: 100,
                  hint: '128',
                ),
                PanelActionButton(
                  icon: Icons.brightness_6,
                  label: 'Set Brightness',
                  tooltipStr: 'Set V4L2 brightness control',
                  onPressed: () {
                    final val = _brightnessCtrl.text.trim();
                    if (val.isNotEmpty) {
                      _send(
                        'v4l2-ctl -d /dev/video0 --set-ctrl=brightness=$val',
                      );
                    }
                  },
                ),
                _inputField(_contrastCtrl, 'Contrast', width: 100, hint: '128'),
                PanelActionButton(
                  icon: Icons.contrast,
                  label: 'Set Contrast',
                  tooltipStr: 'Set V4L2 contrast control',
                  onPressed: () {
                    final val = _contrastCtrl.text.trim();
                    if (val.isNotEmpty) {
                      _send(
                        'v4l2-ctl -d /dev/video0 --set-ctrl=contrast=$val',
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _saturationCtrl,
                  'Saturation',
                  width: 100,
                  hint: '128',
                ),
                PanelActionButton(
                  icon: Icons.color_lens,
                  label: 'Set Saturation',
                  tooltipStr: 'Set V4L2 saturation control',
                  onPressed: () {
                    final val = _saturationCtrl.text.trim();
                    if (val.isNotEmpty) {
                      _send(
                        'v4l2-ctl -d /dev/video0 --set-ctrl=saturation=$val',
                      );
                    }
                  },
                ),
                _inputField(_gainCtrl, 'Gain', width: 100, hint: '64'),
                PanelActionButton(
                  icon: Icons.network_ping,
                  label: 'Set Gain',
                  tooltipStr: 'Set V4L2 sensor gain control',
                  onPressed: () {
                    final val = _gainCtrl.text.trim();
                    if (val.isNotEmpty) {
                      _send('v4l2-ctl -d /dev/video0 --set-ctrl=gain=$val');
                    }
                  },
                ),
                _inputField(_exposureCtrl, 'Exposure', width: 100, hint: '156'),
                PanelActionButton(
                  icon: Icons.timer,
                  label: 'Set Exposure',
                  tooltipStr: 'Set V4L2 absolute exposure time',
                  onPressed: () {
                    final val = _exposureCtrl.text.trim();
                    if (val.isNotEmpty) {
                      _send(
                        'v4l2-ctl -d /dev/video0 --set-ctrl=exposure_time_absolute=$val',
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      // 5. Streaming Server & Network Player
      MyPanelBody(
        icon: Icons.live_tv,
        title: 'CUSTOMS — UVC Network Streaming Server',
        subtitle:
            'Serve camera video over HTTP MJPEG, RTSP or WebRTC to remote clients',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Live Streaming Server Controls'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'HTTP MJPEG Start',
                  'uvc_http_server start',
                  'Start HTTP MJPEG live stream server',
                  Icons.web,
                ),
                _btn(
                  'HTTP MJPEG Stop',
                  'uvc_http_server stop',
                  'Stop HTTP MJPEG live stream server',
                  Icons.web_asset_off,
                ),
                _btn(
                  'RTSP Server Start',
                  'uvc_rtsp_server start',
                  'Start RTSP live video re-streaming server',
                  Icons.wifi_tethering,
                ),
                _btn(
                  'RTSP Server Stop',
                  'uvc_rtsp_server stop',
                  'Stop RTSP live video re-streaming server',
                  Icons.portable_wifi_off,
                ),
                _btn(
                  'Stream Stats',
                  'uvc_stream stats',
                  'Display video streaming frame rate & bitrate statistics',
                  Icons.query_stats,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Streaming Server Port Configuration'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _streamPortCtrl,
                  'Server Port',
                  width: 120,
                  hint: '8080',
                ),
                PanelActionButton(
                  icon: Icons.settings_ethernet,
                  label: 'Set Port',
                  tooltipStr: 'Configure streaming server network port',
                  onPressed: () {
                    final port = _streamPortCtrl.text.trim();
                    if (port.isNotEmpty) {
                      _send('uvc_http_server port $port');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      // 6. Raw Command Interface
      MyPanelBody(
        icon: Icons.terminal,
        title: 'CUSTOMS — UVC Raw Command Interface',
        subtitle: 'Execute custom shell / V4L2 / UVC commands on the target',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Custom UVC Command'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _customCmdCtrl,
                  'Command',
                  width: 240,
                  hint: 'status',
                ),
                PanelActionButton(
                  icon: Icons.send,
                  label: 'Send Cmd',
                  tooltipStr: 'Send raw uvc_stream command to target board',
                  onPressed: () {
                    final cmd = _customCmdCtrl.text.trim();
                    if (cmd.isNotEmpty) {
                      _send(
                        cmd.startsWith('uvc_stream ') ? cmd : 'uvc_stream $cmd',
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildTestPattern() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: CustomPaint(painter: _TestPatternPainter()),
    );
  }
}

/// Helper class to extract JPEG frames from chunked HTTP response streams (MJPEG)
class _MjpegDecoder {
  HttpClient? _client;
  StreamSubscription<List<int>>? _subscription;
  final List<int> _buffer = [];

  void start(
    String url, {
    required Function(Uint8List) onFrame,
    required Function(String) onError,
  }) async {
    stop();
    try {
      final uri = Uri.parse(url);
      _client = HttpClient();
      _client!.connectionTimeout = const Duration(seconds: 5);
      final request = await _client!.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        onError('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        return;
      }

      _subscription = response.listen(
        (data) {
          _buffer.addAll(data);
          _extractFrames(onFrame);
        },
        onError: (err) => onError(err.toString()),
        onDone: () => onError('Stream connection closed'),
        cancelOnError: true,
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  void _extractFrames(Function(Uint8List) onFrame) {
    while (true) {
      int startIdx = -1;
      for (int i = 0; i < _buffer.length - 1; i++) {
        if (_buffer[i] == 0xFF && _buffer[i + 1] == 0xD8) {
          startIdx = i;
          break;
        }
      }
      if (startIdx == -1) {
        if (_buffer.length > 500000) _buffer.clear();
        break;
      }

      int endIdx = -1;
      for (int i = startIdx + 2; i < _buffer.length - 1; i++) {
        if (_buffer[i] == 0xFF && _buffer[i + 1] == 0xD9) {
          endIdx = i + 2;
          break;
        }
      }

      if (endIdx != -1) {
        final frameBytes = Uint8List.fromList(
          _buffer.sublist(startIdx, endIdx),
        );
        onFrame(frameBytes);
        _buffer.removeRange(0, endIdx);
      } else {
        if (startIdx > 0) {
          _buffer.removeRange(0, startIdx);
        }
        break;
      }
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _client?.close(force: true);
    _client = null;
    _buffer.clear();
  }
}

/// Custom painter for SMPTE-style camera test pattern
class _TestPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      Colors.white,
      Colors.yellow,
      Colors.cyan,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.blue,
    ];
    final barWidth = size.width / colors.length;
    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()..color = colors[i];
      canvas.drawRect(
        Rect.fromLTWH(i * barWidth, 0, barWidth, size.height * 0.75),
        paint,
      );
    }
    final bottomPaint = Paint()..color = Colors.grey.shade900;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.75, size.width, size.height * 0.25),
      bottomPaint,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'UVC TEST PATTERN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Consolas',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        size.height * 0.82,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
