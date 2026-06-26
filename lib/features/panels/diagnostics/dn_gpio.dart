import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class DnGpioPanel extends ConsumerStatefulWidget {
  const DnGpioPanel({super.key});

  @override
  ConsumerState<DnGpioPanel> createState() => _DnGpioPanelState();
}

class _DnGpioPanelState extends ConsumerState<DnGpioPanel> {
  final _line = TextEditingController(text: '0');
  final _chip = TextEditingController(text: 'gpiochip0');

  @override
  void dispose() {
    _line.dispose();
    _chip.dispose();
    super.dispose();
  }

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  @override
  Widget build(BuildContext context) {
    PanelActionButton btn(IconData i, String label, String cmd) =>
        PanelActionButton(
          icon: i,
          label: label,
          tooltipStr: cmd,
          onPressed: () => _send(cmd),
        );
    return MyPanel(
      icon: Icons.developer_board,
      panelTitle: 'GPIO Control',
      panelSubtitle: 'Inspect and drive GPIO lines (libgpiod)',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.list,
          title: 'Discover',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.developer_board, 'Detect chips', 'gpiodetect'),
              btn(Icons.info, 'Line info', 'gpioinfo'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.tune,
          title: 'Read / Write Line',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 40,
                    child: TextField(
                      controller: _chip,
                      decoration: const InputDecoration(
                        labelText: 'Chip',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    height: 40,
                    child: TextField(
                      controller: _line,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Line',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PanelActionButton(
                    icon: Icons.download,
                    label: 'Get',
                    tooltipStr: 'gpioget',
                    onPressed: () =>
                        _send('gpioget ${_chip.text} ${_line.text}'),
                  ),
                  PanelActionButton(
                    icon: Icons.toggle_on,
                    label: 'Set High',
                    tooltipStr: 'gpioset =1',
                    onPressed: () =>
                        _send('gpioset ${_chip.text} ${_line.text}=1'),
                  ),
                  PanelActionButton(
                    icon: Icons.toggle_off,
                    label: 'Set Low',
                    tooltipStr: 'gpioset =0',
                    onPressed: () =>
                        _send('gpioset ${_chip.text} ${_line.text}=0'),
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
