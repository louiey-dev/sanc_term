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

  @override
  void dispose() {
    _tempThreshold.dispose();
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
    ];
  }
}
