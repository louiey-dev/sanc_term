import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// State model for preserving RV1106 panel parameters across page transitions
class Rv1106ParamsState {
  final String bitrate;
  final String npuThreshold;
  final String customCmd;

  const Rv1106ParamsState({
    this.bitrate = '2048',
    this.npuThreshold = '0.50',
    this.customCmd = 'status',
  });
}

/// Riverpod provider for persisting RV1106 panel parameter values
final rv1106ParamsProvider = StateProvider<Rv1106ParamsState>(
  (ref) => const Rv1106ParamsState(),
);

/// CUSTOMS — Rockchip RV1106 AI Camera & Subsystem Control Panel
class Rv1106Panel extends ConsumerStatefulWidget {
  final bool standalone;

  const Rv1106Panel({super.key, this.standalone = true});

  @override
  ConsumerState<Rv1106Panel> createState() => _Rv1106PanelState();
}

class _Rv1106PanelState extends ConsumerState<Rv1106Panel> {
  late final TextEditingController _bitrateCtrl;
  late final TextEditingController _npuThresholdCtrl;
  late final TextEditingController _customCmdCtrl;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(rv1106ParamsProvider);
    _bitrateCtrl = TextEditingController(text: saved.bitrate);
    _npuThresholdCtrl = TextEditingController(text: saved.npuThreshold);
    _customCmdCtrl = TextEditingController(text: saved.customCmd);

    _bitrateCtrl.addListener(_saveParams);
    _npuThresholdCtrl.addListener(_saveParams);
    _customCmdCtrl.addListener(_saveParams);
  }

  void _saveParams() {
    ref.read(rv1106ParamsProvider.notifier).state = Rv1106ParamsState(
      bitrate: _bitrateCtrl.text,
      npuThreshold: _npuThresholdCtrl.text,
      customCmd: _customCmdCtrl.text,
    );
  }

  @override
  void dispose() {
    _bitrateCtrl.dispose();
    _npuThresholdCtrl.dispose();
    _customCmdCtrl.dispose();
    super.dispose();
  }

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  PanelActionButton _btn(
    String label,
    String cmd,
    String tip, [
    IconData? icon,
  ]) => PanelActionButton(
    icon: icon ?? Icons.memory,
    label: label,
    tooltipStr: tip,
    onPressed: () => _send(cmd),
  );

  Widget _inputField(
    TextEditingController controller,
    String label, {
    double width = 140,
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
        icon: Icons.memory,
        panelTitle: 'RV1106 AI Camera Panel',
        panelSubtitle: 'Rockchip RV1106 ISP, NPU, MPP VPU & IPC controls',
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
      MyPanelBody(
        icon: Icons.memory,
        title: 'CUSTOMS — RV1106 System & CPU Status',
        subtitle: 'Cortex-A7 SoC status, clock frequencies, thermal & memory',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('SoC Hardware & System Info'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'SoC Info',
                  'dmesg | grep -i rv1106 || cat /proc/cpuinfo',
                  'Show RV1106 SoC identification & CPU details',
                  Icons.info_outline,
                ),
                _btn(
                  'CPU Freq',
                  'cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null',
                  'Read current CPU clock frequency',
                  Icons.speed,
                ),
                _btn(
                  'Memory',
                  'free -m',
                  'Display memory usage summary',
                  Icons.sd_storage,
                ),
                _btn(
                  'Thermal',
                  'cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null',
                  'Read SoC thermal sensor temperatures',
                  Icons.thermostat,
                ),
                _btn(
                  'Uptime',
                  'uptime',
                  'Show system uptime & load average',
                  Icons.access_time,
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.camera,
        title: 'CUSTOMS — RV1106 ISP 3.0 & Sensor Control',
        subtitle: 'Camera VICAP, ISP pipeline, IR-Cut & night mode settings',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Camera & ISP Pipeline Controls'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'ISP Status',
                  'cat /proc/rkisp-vir0/summary 2>/dev/null || v4l2-ctl --list-devices',
                  'Show RKISP 3.0 driver summary & video devices',
                  Icons.camera_alt,
                ),
                _btn(
                  'Media Topology',
                  'media-ctl -p 2>/dev/null',
                  'Print V4L2 media controller topology tree',
                  Icons.account_tree,
                ),
                _btn(
                  'IRCUT ON',
                  'rv1106_cam ircut 1',
                  'Enable IR-Cut filter (Day Mode)',
                  Icons.wb_sunny,
                ),
                _btn(
                  'IRCUT OFF',
                  'rv1106_cam ircut 0',
                  'Disable IR-Cut filter (Night / IR Mode)',
                  Icons.nights_stay,
                ),
                _btn(
                  'ISP Stream Start',
                  'rv1106_cam isp start',
                  'Start VICAP / ISP video stream',
                  Icons.videocam,
                ),
                _btn(
                  'ISP Stream Stop',
                  'rv1106_cam isp stop',
                  'Stop VICAP / ISP video stream',
                  Icons.videocam_off,
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.psychology,
        title: 'CUSTOMS — RV1106 NPU & AI Engine',
        subtitle: '0.5 TOPs NPU load, model inference & detection parameters',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('NPU Engine Controls'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'NPU Load',
                  'cat /sys/kernel/debug/rknpu/load 2>/dev/null',
                  'Read RKNPU hardware engine utilization load',
                  Icons.query_stats,
                ),
                _btn(
                  'NPU Freq',
                  'cat /sys/class/devfreq/ffbc0000.npu/cur_freq 2>/dev/null',
                  'Read RKNPU clock frequency',
                  Icons.speed,
                ),
                _btn(
                  'AI Start',
                  'rv1106_npu detect start',
                  'Start AI object detection model inference loop',
                  Icons.play_arrow,
                ),
                _btn(
                  'AI Stop',
                  'rv1106_npu detect stop',
                  'Stop AI object detection model inference loop',
                  Icons.stop,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('AI Confidence Threshold'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _npuThresholdCtrl,
                  'Confidence (0.0..1.0)',
                  width: 160,
                  hint: '0.50',
                ),
                PanelActionButton(
                  icon: Icons.tune,
                  label: 'Set Threshold',
                  tooltipStr: 'rv1106_npu threshold <val>',
                  onPressed: () {
                    final val = _npuThresholdCtrl.text.trim();
                    if (val.isNotEmpty) {
                      _send('rv1106_npu threshold $val');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.video_settings,
        title: 'CUSTOMS — RV1106 VPU / MPP & RTSP Stream',
        subtitle: 'Media Process Platform (MPP), H.264/H.265 VENC & RTSP server',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Media Encoder & RTSP Controls'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'MPP Load',
                  'cat /proc/mpp_service/load 2>/dev/null',
                  'Show Rockchip MPP encoder load status',
                  Icons.bar_chart,
                ),
                _btn(
                  'RTSP Start',
                  'rv1106_rtsp start',
                  'Start RTSP live video streaming server',
                  Icons.live_tv,
                ),
                _btn(
                  'RTSP Stop',
                  'rv1106_rtsp stop',
                  'Stop RTSP live video streaming server',
                  Icons.portable_wifi_off,
                ),
                _btn(
                  'Codec H.264',
                  'rv1106_venc codec h264',
                  'Set video encoder format to H.264 AVC',
                  Icons.video_file,
                ),
                _btn(
                  'Codec H.265',
                  'rv1106_venc codec h265',
                  'Set video encoder format to H.265 HEVC',
                  Icons.video_file_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Video Bitrate Configuration'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _bitrateCtrl,
                  'Bitrate (kbps)',
                  width: 140,
                  hint: '2048',
                ),
                PanelActionButton(
                  icon: Icons.settings,
                  label: 'Set Bitrate',
                  tooltipStr: 'rv1106_venc bitrate <kbps>',
                  onPressed: () {
                    final val = _bitrateCtrl.text.trim();
                    if (val.isNotEmpty) {
                      _send('rv1106_venc bitrate $val');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.terminal,
        title: 'CUSTOMS — RV1106 Raw Command Interface',
        subtitle: 'Execute custom shell / RV1106 IPC commands',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Custom RV1106 Command'),
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
                  tooltipStr: 'Send raw rv1106 command to board',
                  onPressed: () {
                    final cmd = _customCmdCtrl.text.trim();
                    if (cmd.isNotEmpty) {
                      _send(cmd.startsWith('rv1106 ') ? cmd : 'rv1106 $cmd');
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
}
