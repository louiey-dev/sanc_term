import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/common.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// Rockchip GPIO via sysfs. gpio number = bank*32 + group*8 + pin
/// (group A=0, B=1, C=2, D=3).
class RcGpioPanel extends ConsumerStatefulWidget {
  const RcGpioPanel({super.key});

  @override
  ConsumerState<RcGpioPanel> createState() => _RcGpioPanelState();
}

class _RcGpioPanelState extends ConsumerState<RcGpioPanel> {
  static const _groups = ['A', 'B', 'C', 'D'];

  int _bank = 1;
  String _group = 'A';
  int _pin = 1;
  String _direction = 'out';

  int get _gpio => _bank * 32 + _groups.indexOf(_group) * 8 + _pin;

  DropdownMenuItem<T> _item<T>(T v, String label) => DropdownMenuItem(
        value: v,
        child: Text(label,
            style: const TextStyle(fontSize: 12, fontFamily: 'Consolas')),
      );

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MyPanel(
      icon: Icons.developer_board,
      panelTitle: 'Rockchip GPIO',
      panelSubtitle: 'Configure and test Rockchip GPIO pins',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.developer_board,
          title: 'GPIO Control',
          subtitle: 'gpio$_gpio (bank $_bank · $_group · pin $_pin)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  buildDropdown<int>(
                    context,
                    value: _bank,
                    items: [for (var i = 0; i < 16; i++) _item(i, 'GPIO$i')],
                    onChanged: (v) {
                      if (v != null) setState(() => _bank = v);
                    },
                    width: 90,
                  ),
                  buildDropdown<String>(
                    context,
                    value: _group,
                    items: _groups.map((g) => _item(g, g)).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _group = v);
                    },
                    width: 70,
                  ),
                  buildDropdown<int>(
                    context,
                    value: _pin,
                    items: [for (var i = 0; i < 8; i++) _item(i, '$i')],
                    onChanged: (v) {
                      if (v != null) setState(() => _pin = v);
                    },
                    width: 70,
                  ),
                  Text('= gpio$_gpio',
                      style: TextStyle(
                          fontFamily: 'Consolas',
                          fontWeight: FontWeight.w700,
                          color: c.primary)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PanelActionButton(
                    icon: Icons.login,
                    label: 'export',
                    tooltipStr: 'export gpio',
                    onPressed: () =>
                        _send('echo $_gpio > /sys/class/gpio/export'),
                  ),
                  buildDropdown<String>(
                    context,
                    value: _direction,
                    items: ['in', 'out'].map((d) => _item(d, d)).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _direction = v);
                    },
                    width: 70,
                  ),
                  PanelActionButton(
                    icon: Icons.swap_vert,
                    label: 'Direction',
                    tooltipStr: 'set direction',
                    onPressed: () => _send(
                        'echo $_direction > /sys/class/gpio/gpio$_gpio/direction'),
                  ),
                  PanelActionButton(
                    icon: Icons.arrow_upward,
                    label: 'HIGH',
                    tooltipStr: 'set value 1',
                    onPressed: () =>
                        _send('echo 1 > /sys/class/gpio/gpio$_gpio/value'),
                  ),
                  PanelActionButton(
                    icon: Icons.arrow_downward,
                    label: 'LOW',
                    tooltipStr: 'set value 0',
                    onPressed: () =>
                        _send('echo 0 > /sys/class/gpio/gpio$_gpio/value'),
                  ),
                  PanelActionButton(
                    icon: Icons.logout,
                    label: 'unexport',
                    tooltipStr: 'unexport gpio',
                    onPressed: () =>
                        _send('echo $_gpio > /sys/class/gpio/unexport'),
                  ),
                  PanelActionButton(
                    icon: Icons.list,
                    label: 'List',
                    tooltipStr: 'ls -al /sys/class/gpio',
                    onPressed: () => _send('ls -al /sys/class/gpio'),
                  ),
                ],
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.light_mode,
          title: 'LEDs',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PanelActionButton(
                icon: Icons.list,
                label: 'LED List',
                tooltipStr: 'ls -al /sys/class/leds',
                onPressed: () => _send('ls -al /sys/class/leds'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
