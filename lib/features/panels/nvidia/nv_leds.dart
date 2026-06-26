import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/nvidia/nv_common.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class NvLedPanel extends ConsumerStatefulWidget {
  const NvLedPanel({super.key});

  @override
  ConsumerState<NvLedPanel> createState() => _NvLedPanelState();
}

class _NvLedPanelState extends ConsumerState<NvLedPanel> {
  final _led = TextEditingController(text: 'led_eno1');
  final _brightness = TextEditingController(text: '1');

  @override
  void dispose() {
    _led.dispose();
    _brightness.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MyPanel(
      icon: Icons.light_mode,
      panelTitle: 'nVidia LED Control',
      panelSubtitle: 'Manage board LEDs',
      panelActions: const [NvCommonActions()],
      children: [
        MyPanelBody(
          icon: Icons.light_mode,
          title: 'LED Control',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                'cat /sys/class/leds/<led>/max_brightness\n'
                'echo 1 | sudo tee /sys/class/leds/<led>/brightness',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Consolas',
                  color: c.muted,
                ),
              ),
              const SizedBox(height: 14),
              PanelActionButton(
                icon: Icons.list,
                label: 'List LEDs',
                tooltipStr: 'ls -al /sys/class/leds',
                onPressed: () =>
                    sendBoardCommand(ref, context, 'ls -al /sys/class/leds'),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownMenu<String>(
                    width: 180,
                    controller: _led,
                    initialSelection: 'led_eno1',
                    label: const Text('LED Name'),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 'led_eno1', label: 'led_eno1'),
                      DropdownMenuEntry(value: 'led_eth1', label: 'led_eth1'),
                    ],
                  ),
                  DropdownMenu<String>(
                    width: 140,
                    controller: _brightness,
                    initialSelection: '1',
                    label: const Text('Brightness'),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: '1', label: 'On'),
                      DropdownMenuEntry(value: '0', label: 'Off'),
                    ],
                  ),
                  PanelActionButton(
                    icon: Icons.download,
                    label: 'Get Brightness',
                    tooltipStr: 'read max_brightness',
                    onPressed: () => sendBoardCommand(
                      ref,
                      context,
                      'cat /sys/class/leds/${_led.text}/max_brightness',
                    ),
                  ),
                  PanelActionButton(
                    icon: Icons.upload,
                    label: 'Set Brightness',
                    tooltipStr: 'write brightness',
                    onPressed: () => sendBoardCommand(
                      ref,
                      context,
                      'echo ${_brightness.text == 'On' ? '1' : '0'} | sudo tee /sys/class/leds/${_led.text}/brightness',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
