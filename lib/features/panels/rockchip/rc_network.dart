import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class RcNetworkPanel extends ConsumerStatefulWidget {
  const RcNetworkPanel({super.key});

  @override
  ConsumerState<RcNetworkPanel> createState() => _RcNetworkPanelState();
}

class _RcNetworkPanelState extends ConsumerState<RcNetworkPanel> {
  final _ping = TextEditingController(text: '8.8.8.8');

  @override
  void dispose() {
    _ping.dispose();
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
      icon: Icons.lan,
      panelTitle: 'Rockchip Network',
      panelSubtitle: 'Ethernet and networking',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.lan,
          title: 'Interfaces',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.list, 'Interfaces', 'ip link show'),
              btn(Icons.lan, 'IP addr', 'ip addr show'),
              btn(Icons.route, 'IP route', 'ip route show'),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.network_ping,
          title: 'Connectivity',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 40,
                child: TextField(
                  controller: _ping,
                  decoration: const InputDecoration(
                    labelText: 'IP Address',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              PanelActionButton(
                icon: Icons.network_ping,
                label: 'Ping',
                tooltipStr: 'ping -c 4',
                onPressed: () => _send('ping -c 4 ${_ping.text}'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
