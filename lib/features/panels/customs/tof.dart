import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// State model for preserving ToF panel parameters across page transitions
class TofParamsState {
  final String integrationTime;
  final String maxDistance;
  final String calibDistance;
  final String crosstalkVal;
  final String customCmd;

  const TofParamsState({
    this.integrationTime = '1000',
    this.maxDistance = '4000',
    this.calibDistance = '1000',
    this.crosstalkVal = '50',
    this.customCmd = 'status',
  });
}

/// Riverpod provider for persisting ToF panel parameter values
final tofParamsProvider = StateProvider<TofParamsState>(
  (ref) => const TofParamsState(),
);

/// CUSTOMS — Time-of-Flight (ToF) Camera Panel
class TofPanel extends ConsumerStatefulWidget {
  final bool standalone;

  const TofPanel({super.key, this.standalone = true});

  @override
  ConsumerState<TofPanel> createState() => _TofPanelState();
}

class _TofPanelState extends ConsumerState<TofPanel> {
  // TOF Camera Controllers
  late final TextEditingController _tofIntegrationTime;
  late final TextEditingController _tofMaxDistance;
  late final TextEditingController _tofCalibDistance;
  late final TextEditingController _tofCrosstalkVal;
  late final TextEditingController _customCmd;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(tofParamsProvider);
    _tofIntegrationTime = TextEditingController(text: saved.integrationTime);
    _tofMaxDistance = TextEditingController(text: saved.maxDistance);
    _tofCalibDistance = TextEditingController(text: saved.calibDistance);
    _tofCrosstalkVal = TextEditingController(text: saved.crosstalkVal);
    _customCmd = TextEditingController(text: saved.customCmd);

    _tofIntegrationTime.addListener(_saveParams);
    _tofMaxDistance.addListener(_saveParams);
    _tofCalibDistance.addListener(_saveParams);
    _tofCrosstalkVal.addListener(_saveParams);
    _customCmd.addListener(_saveParams);
  }

  void _saveParams() {
    ref.read(tofParamsProvider.notifier).state = TofParamsState(
      integrationTime: _tofIntegrationTime.text,
      maxDistance: _tofMaxDistance.text,
      calibDistance: _tofCalibDistance.text,
      crosstalkVal: _tofCrosstalkVal.text,
      customCmd: _customCmd.text,
    );
  }

  @override
  void dispose() {
    _tofIntegrationTime.dispose();
    _tofMaxDistance.dispose();
    _tofCalibDistance.dispose();
    _tofCrosstalkVal.dispose();
    _customCmd.dispose();
    super.dispose();
  }

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  PanelActionButton _btn(
    String label,
    String cmd,
    String tip, [
    IconData? icon,
  ]) => PanelActionButton(
    icon: icon ?? Icons.sensors,
    label: label,
    tooltipStr: tip,
    onPressed: () => _send(cmd),
  );

  Widget _inputField(
    TextEditingController controller,
    String label, {
    double width = 130,
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
    child: SelectableText(
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
        icon: Icons.sensors,
        panelTitle: 'ToF Panel',
        panelSubtitle:
            'Time-of-Flight range sensor configuration & calibration',
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
        icon: Icons.sensors,
        title: 'CUSTOMS — TOF Camera Config',
        subtitle:
            'Integration time, max distance threshold & stream control',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('TOF Stream & Control'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'TOF Status',
                  'fire_cam tof status',
                  'Show TOF sensor status & parameters',
                  Icons.info_outline,
                ),
                _btn(
                  'Stream Start',
                  'fire_cam tof stream start',
                  'Start TOF distance range stream',
                  Icons.play_arrow,
                ),
                _btn(
                  'Stream Stop',
                  'fire_cam tof stream stop',
                  'Stop TOF distance range stream',
                  Icons.stop,
                ),
                _btn(
                  'Dump Raw',
                  'fire_cam tof dump_raw',
                  'Dump raw TOF range frame data',
                  Icons.receipt_long,
                ),
                _btn(
                  'Reset TOF',
                  'fire_cam tof reset',
                  'Reset TOF camera hardware module',
                  Icons.restart_alt,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('TOF Parameters Configuration'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _tofIntegrationTime,
                  'Integration (us)',
                  width: 140,
                  hint: '1000',
                ),
                PanelActionButton(
                  icon: Icons.tune,
                  label: 'Set Integration',
                  tooltipStr: 'fire_cam tof integration <us>',
                  onPressed: () {
                    final val = _tofIntegrationTime.text.trim();
                    if (val.isNotEmpty) {
                      _send('fire_cam tof integration $val');
                    }
                  },
                ),
                _inputField(
                  _tofMaxDistance,
                  'Max Dist (mm)',
                  width: 130,
                  hint: '4000',
                ),
                PanelActionButton(
                  icon: Icons.straighten,
                  label: 'Set Max Dist',
                  tooltipStr: 'fire_cam tof max_dist <mm>',
                  onPressed: () {
                    final val = _tofMaxDistance.text.trim();
                    if (val.isNotEmpty) {
                      _send('fire_cam tof max_dist $val');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.build,
        title: 'CUSTOMS — TOF Camera Calibration',
        subtitle:
            'Offset distance, crosstalk compensation & zero-point calibration',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Offset & Crosstalk Calibration'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _tofCalibDistance,
                  'Calib Dist (mm)',
                  width: 130,
                  hint: '1000',
                ),
                PanelActionButton(
                  icon: Icons.center_focus_strong,
                  label: 'Calib Offset',
                  tooltipStr: 'fire_cam tof calib offset <dist_mm>',
                  onPressed: () {
                    final val = _tofCalibDistance.text.trim();
                    if (val.isNotEmpty) {
                      _send('fire_cam tof calib offset $val');
                    }
                  },
                ),
                _inputField(
                  _tofCrosstalkVal,
                  'Crosstalk Val',
                  width: 130,
                  hint: '50',
                ),
                PanelActionButton(
                  icon: Icons.blur_on,
                  label: 'Calib Crosstalk',
                  tooltipStr: 'fire_cam tof calib crosstalk <val>',
                  onPressed: () {
                    final val = _tofCrosstalkVal.text.trim();
                    if (val.isNotEmpty) {
                      _send('fire_cam tof calib crosstalk $val');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Calibration Commands'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Zero Calib',
                  'fire_cam tof calib zero',
                  'Perform zero-distance calibration',
                  Icons.exposure_zero,
                ),
                _btn(
                  'Temp Comp',
                  'fire_cam tof calib temp',
                  'Run temperature compensation calibration',
                  Icons.thermostat,
                ),
                _btn(
                  'Reset Calib',
                  'fire_cam tof calib reset',
                  'Reset calibration parameters to factory defaults',
                  Icons.restore,
                ),
                _btn(
                  'Save Calib',
                  'fire_cam tof calib save',
                  'Save current calibration data to non-volatile memory',
                  Icons.save,
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.fact_check,
        title: 'CUSTOMS — TOF Read Calibration Data',
        subtitle:
            'Inspect factory, active and raw calibration registers',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Read Calibration Data'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Read Offset',
                  'fire_cam tof calib read offset',
                  'Read current distance offset calibration parameter',
                  Icons.straighten,
                ),
                _btn(
                  'Read Crosstalk',
                  'fire_cam tof calib read crosstalk',
                  'Read active crosstalk compensation table',
                  Icons.blur_on,
                ),
                _btn(
                  'Read Temp',
                  'fire_cam tof calib read temp',
                  'Read temperature calibration coefficient data',
                  Icons.thermostat,
                ),
                _btn(
                  'Read Factory',
                  'fire_cam tof calib read factory',
                  'Read factory default calibration data set',
                  Icons.inventory_2,
                ),
                _btn(
                  'Read Active',
                  'fire_cam tof calib read active',
                  'Read currently active in-memory calibration data',
                  Icons.memory,
                ),
                _btn(
                  'Dump Calib',
                  'fire_cam tof calib read dump',
                  'Dump full raw calibration EEPROM contents',
                  Icons.developer_board,
                ),
                _btn(
                  'Read Raw Registers',
                  'fire_cam tof calib read raw',
                  'Read low-level TOF sensor hardware registers',
                  Icons.code,
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.terminal,
        title: 'CUSTOMS — TOF Raw Command Interface',
        subtitle: 'Execute custom shell / TOF commands on target',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Custom TOF Command'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _customCmd,
                  'Command',
                  width: 240,
                  hint: 'status',
                ),
                PanelActionButton(
                  icon: Icons.send,
                  label: 'Send Cmd',
                  tooltipStr: 'Send raw TOF command to board',
                  onPressed: () {
                    final cmd = _customCmd.text.trim();
                    if (cmd.isNotEmpty) {
                      _send(
                        cmd.startsWith('fire_cam tof ')
                            ? cmd
                            : cmd.startsWith('tof ')
                            ? 'fire_cam $cmd'
                            : 'fire_cam tof $cmd',
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
}
