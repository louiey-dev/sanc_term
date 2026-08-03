import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// CUSTOMS — Fire Camera & Thermal Monitoring Panel
class FireCamPanel extends ConsumerStatefulWidget {
  final bool standalone;

  const FireCamPanel({super.key, this.standalone = true});

  @override
  ConsumerState<FireCamPanel> createState() => _FireCamPanelState();
}

class _FireCamPanelState extends ConsumerState<FireCamPanel> {
  final _tempThreshold = TextEditingController(text: '75.0');
  final _customCmd = TextEditingController(text: 'status');

  // TOF Camera Controllers
  final _tofIntegrationTime = TextEditingController(text: '1000');
  final _tofMaxDistance = TextEditingController(text: '4000');
  final _tofCalibDistance = TextEditingController(text: '1000');
  final _tofCrosstalkVal = TextEditingController(text: '50');

  @override
  void dispose() {
    _tempThreshold.dispose();
    _customCmd.dispose();
    _tofIntegrationTime.dispose();
    _tofMaxDistance.dispose();
    _tofCalibDistance.dispose();
    _tofCrosstalkVal.dispose();
    super.dispose();
  }

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  PanelActionButton _btn(
    String label,
    String cmd,
    String tip, [
    IconData? icon,
  ]) => PanelActionButton(
    icon: icon ?? Icons.local_fire_department,
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
        icon: Icons.local_fire_department,
        panelTitle: 'Fire Cam Panel',
        panelSubtitle: 'Thermal & Fire Camera controls, status & stream',
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
        icon: Icons.local_fire_department,
        title: 'CUSTOMS — Fire Camera Control',
        subtitle: 'Thermal imaging, fire detection threshold & sensor stream',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Camera & Stream Control'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Status',
                  'fire_cam status',
                  'Show Fire Cam status',
                  Icons.info_outline,
                ),
                _btn(
                  'Stream Start',
                  'fire_cam stream start',
                  'Start thermal video stream',
                  Icons.videocam,
                ),
                _btn(
                  'Stream Stop',
                  'fire_cam stream stop',
                  'Stop thermal video stream',
                  Icons.videocam_off,
                ),
                _btn(
                  'Calibrate',
                  'fire_cam calibrate',
                  'Calibrate thermal sensor zero-point',
                  Icons.tune,
                ),
                _btn(
                  'Alarm Test',
                  'fire_cam alarm test',
                  'Test fire detection alarm trigger',
                  Icons.warning_amber,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Temperature Threshold Config'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _tempThreshold,
                  'Max Temp (°C)',
                  width: 140,
                  hint: '75.0',
                ),
                PanelActionButton(
                  icon: Icons.thermostat,
                  label: 'Set Threshold',
                  tooltipStr: 'fire_cam temp_threshold <value>',
                  onPressed: () {
                    final val = _tempThreshold.text.trim();
                    if (val.isNotEmpty) {
                      _send('fire_cam temp_threshold $val');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Custom Fire Cam Command'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _customCmd,
                  'Command',
                  width: 220,
                  hint: 'status',
                ),
                PanelActionButton(
                  icon: Icons.send,
                  label: 'Send Cmd',
                  tooltipStr: 'Send raw fire_cam command',
                  onPressed: () {
                    final cmd = _customCmd.text.trim();
                    if (cmd.isNotEmpty) {
                      _send(cmd.startsWith('fire_cam ') ? cmd : 'fire_cam $cmd');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.sensors,
        title: 'CUSTOMS — TOF Camera Config',
        subtitle: 'Time-of-Flight range sensor stream, control & timing parameters',
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
                  Icons.videocam,
                ),
                _btn(
                  'Stream Stop',
                  'fire_cam tof stream stop',
                  'Stop TOF distance range stream',
                  Icons.videocam_off,
                ),
                _btn(
                  'Dump Raw Frame',
                  'fire_cam tof dump_raw',
                  'Dump raw TOF range frame data',
                  Icons.data_object,
                ),
                _btn(
                  'Reset TOF',
                  'fire_cam tof reset',
                  'Reset TOF camera hardware module',
                  Icons.refresh,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Timing & Range Parameters'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _tofIntegrationTime,
                  'Integration (µs)',
                  width: 140,
                  hint: '1000',
                ),
                PanelActionButton(
                  icon: Icons.timer,
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
                  width: 140,
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
        icon: Icons.tune,
        title: 'CUSTOMS — TOF Camera Calibration',
        subtitle: 'Distance offset, crosstalk & thermal drift calibration routines',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Distance Offset Calibration'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _tofCalibDistance,
                  'Target Dist (mm)',
                  width: 140,
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
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Crosstalk Calibration'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _tofCrosstalkVal,
                  'Reflectance (%)',
                  width: 140,
                  hint: '50',
                ),
                PanelActionButton(
                  icon: Icons.grid_on,
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
            _sectionLabel('Calibration Operations'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Zero Point',
                  'fire_cam tof calib zero',
                  'Perform zero-point offset calibration',
                  Icons.exposure_zero,
                ),
                _btn(
                  'Temp Comp',
                  'fire_cam tof calib temp',
                  'Calibrate temperature drift compensation',
                  Icons.thermostat,
                ),
                _btn(
                  'Reset Calib',
                  'fire_cam tof calib reset',
                  'Restore factory default calibration',
                  Icons.restore,
                ),
                _btn(
                  'Save NVRAM',
                  'fire_cam tof calib save',
                  'Save calibration parameters to NVRAM',
                  Icons.save,
                ),
              ],
            ),
          ],
        ),
      ),
      MyPanelBody(
        icon: Icons.table_chart_outlined,
        title: 'CUSTOMS — TOF Read Calibration Data',
        subtitle: 'Read offset, crosstalk, factory ROM & active calibration matrices',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Calibration Tables & Memory'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Read Offset',
                  'fire_cam tof calib read offset',
                  'Read TOF distance offset calibration data',
                  Icons.straighten,
                ),
                _btn(
                  'Read Crosstalk',
                  'fire_cam tof calib read crosstalk',
                  'Read TOF crosstalk calibration matrix',
                  Icons.grid_view,
                ),
                _btn(
                  'Read Temp Table',
                  'fire_cam tof calib read temp',
                  'Read temperature compensation table',
                  Icons.thermostat_auto,
                ),
                _btn(
                  'Read Factory',
                  'fire_cam tof calib read factory',
                  'Read factory default calibration ROM data',
                  Icons.factory,
                ),
                _btn(
                  'Read Active',
                  'fire_cam tof calib read active',
                  'Read current active calibration parameters',
                  Icons.memory,
                ),
                _btn(
                  'Dump Matrix',
                  'fire_cam tof calib read dump',
                  'Dump full TOF calibration memory table',
                  Icons.developer_board,
                ),
                _btn(
                  'Dump Raw Data',
                  'fire_cam tof calib read raw',
                  'Dump raw TOF sensor & calibration memory data',
                  Icons.data_array,
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }
}
