import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class RcSensorsPanel extends ConsumerStatefulWidget {
  const RcSensorsPanel({super.key});

  @override
  ConsumerState<RcSensorsPanel> createState() => _RcSensorsPanelState();
}

class _RcSensorsPanelState extends ConsumerState<RcSensorsPanel> {
  final _brightness = TextEditingController(text: '100');

  static const _light =
      'cat /sys/bus/iio/devices/iio:device1/in_illuminance_input';
  static const _blPath = '/sys/class/backlight/backlight';

  @override
  void dispose() {
    _brightness.dispose();
    super.dispose();
  }

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  @override
  Widget build(BuildContext context) {
    return MyPanel(
      icon: Icons.sensors,
      panelTitle: 'Rockchip Sensors',
      panelSubtitle: 'Light sensor and backlight',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.light_mode_outlined,
          title: 'Light Sensor',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PanelActionButton(
                icon: Icons.light_mode_outlined,
                label: 'Read',
                tooltipStr: _light,
                onPressed: () => _send(_light),
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.light_mode,
          title: 'Backlight',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PanelActionButton(
                icon: Icons.light_mode,
                label: 'Read Max',
                tooltipStr: 'max_brightness',
                onPressed: () => _send('cat $_blPath/max_brightness'),
              ),
              PanelActionButton(
                icon: Icons.light_mode,
                label: 'Read Current',
                tooltipStr: 'brightness',
                onPressed: () => _send('cat $_blPath/brightness'),
              ),
              SizedBox(
                width: 90,
                height: 40,
                child: TextField(
                  controller: _brightness,
                  decoration: const InputDecoration(
                    labelText: 'Value',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              PanelActionButton(
                icon: Icons.light_mode,
                label: 'Set',
                tooltipStr: 'set brightness',
                onPressed: () =>
                    _send('echo ${_brightness.text} > $_blPath/brightness'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
