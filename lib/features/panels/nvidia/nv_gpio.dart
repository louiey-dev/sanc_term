import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/nvidia/nv_common.dart';
import 'package:sanc_term/features/panels/nvidia/nv_gpio_data.dart';
import 'package:sanc_term/shared/widgets/common.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class NvGpioPanel extends ConsumerStatefulWidget {
  const NvGpioPanel({super.key});

  @override
  ConsumerState<NvGpioPanel> createState() => _NvGpioPanelState();
}

class _NvGpioPanelState extends ConsumerState<NvGpioPanel> {
  String _chip = 'gpiochip0';
  String _port = kTegraMainPorts.keys.first;
  int _pin = 0;
  bool _high = false;

  Map<String, int> get _ports =>
      _chip == 'gpiochip0' ? kTegraMainPorts : kTegraAonPorts;

  int get _offset => (_ports[_port] ?? 0) * 8 + _pin;

  DropdownMenuItem<T> _item<T>(T value, String label) => DropdownMenuItem(
        value: value,
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontFamily: 'Consolas'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MyPanel(
      icon: Icons.developer_board,
      panelTitle: 'nVidia GPIOs',
      panelSubtitle: 'GPIO configuration and control',
      panelActions: const [NvCommonActions()],
      children: [
        MyPanelBody(
          icon: Icons.info_outline,
          title: 'GPIO Info',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PanelActionButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'gpiodetect',
                    tooltipStr: 'gpiodetect',
                    onPressed: () =>
                        sendBoardCommand(ref, context, 'gpiodetect'),
                  ),
                  PanelActionButton(
                    icon: Icons.info_outline,
                    label: 'gpioinfo',
                    tooltipStr: 'gpioinfo',
                    onPressed: () => sendBoardCommand(ref, context, 'gpioinfo'),
                  ),
                  PanelActionButton(
                    icon: Icons.info_outline,
                    label: 'gpiochip0',
                    tooltipStr: 'gpioinfo gpiochip0',
                    onPressed: () =>
                        sendBoardCommand(ref, context, 'gpioinfo gpiochip0'),
                  ),
                  PanelActionButton(
                    icon: Icons.info_outline,
                    label: 'gpiochip1',
                    tooltipStr: 'gpioinfo gpiochip1',
                    onPressed: () =>
                        sendBoardCommand(ref, context, 'gpioinfo gpiochip1'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Offset = (Port Index × 8) + Pin\n'
                'e.g. PM.00 → Port M index 12 → (12×8)+0 = 96',
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.tune,
          title: 'GPIO Control',
          subtitle: 'Computed: $_chip offset $_offset',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              buildDropdown<String>(
                context,
                value: _chip,
                items: [_item('gpiochip0', 'gpiochip0'), _item('gpiochip1', 'gpiochip1')],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _chip = v;
                      _port = _ports.keys.first;
                    });
                  }
                },
                width: 110,
              ),
              buildDropdown<String>(
                context,
                value: _port,
                items: _ports.keys.map((p) => _item(p, p)).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _port = v);
                },
                width: 80,
              ),
              buildDropdown<int>(
                context,
                value: _pin,
                items: List.generate(8, (i) => _item(i, '$i')),
                onChanged: (v) {
                  if (v != null) setState(() => _pin = v);
                },
                width: 70,
              ),
              buildDropdown<bool>(
                context,
                value: _high,
                items: [_item(false, 'LOW'), _item(true, 'HIGH')],
                onChanged: (v) {
                  if (v != null) setState(() => _high = v);
                },
                width: 80,
              ),
              PanelActionButton(
                icon: Icons.output,
                label: 'gpioset',
                tooltipStr: 'gpioset',
                onPressed: () => sendBoardCommand(
                  ref,
                  context,
                  'gpioset $_chip $_offset=${_high ? 1 : 0} &',
                ),
              ),
              PanelActionButton(
                icon: Icons.input,
                label: 'gpioget',
                tooltipStr: 'gpioget',
                onPressed: () =>
                    sendBoardCommand(ref, context, 'gpioget $_chip $_offset'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
