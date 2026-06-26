import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/nvidia/nv_common.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class NvEthernetPanel extends ConsumerStatefulWidget {
  const NvEthernetPanel({super.key});

  @override
  ConsumerState<NvEthernetPanel> createState() => _NvEthernetPanelState();
}

class _NvEthernetPanelState extends ConsumerState<NvEthernetPanel> {
  final _link = TextEditingController(text: 'eno1');
  final _ping = TextEditingController(text: '8.8.8.8');

  @override
  void dispose() {
    _link.dispose();
    _ping.dispose();
    super.dispose();
  }

  String get _if => _link.text;

  // [command] is evaluated lazily so it always reflects the current interface
  // ([_if]) and ping target, even if the widget hasn't rebuilt since selection.
  PanelActionButton _cmd(String label, String Function() command,
          {String? tip}) =>
      PanelActionButton(
        icon: Icons.lan,
        label: label,
        tooltipStr: tip ?? command(),
        onPressed: () => sendBoardCommand(ref, context, command()),
      );

  @override
  Widget build(BuildContext context) {
    return MyPanel(
      icon: Icons.lan,
      panelTitle: 'nVidia Ethernet',
      panelSubtitle: 'Ethernet configuration and base info',
      panelActions: const [NvCommonActions()],
      children: [
        MyPanelBody(
          icon: Icons.settings_ethernet,
          title: 'Interface / Link Status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownMenu<String>(
                width: 160,
                controller: _link,
                initialSelection: 'eno1',
                label: const Text('I/F Name'),
                onSelected: (_) => setState(() {}),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'eno1', label: 'eno1'),
                  DropdownMenuEntry(value: 'eth1', label: 'eth1'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _cmd('List interfaces', () => 'ip link show'),
                  _cmd('IP addr', () => 'ip addr show'),
                  _cmd('Interface State',
                      () => 'cat /sys/class/net/$_if/operstate'),
                  _cmd('MAC addr', () => 'cat /sys/class/net/$_if/address'),
                  _cmd('speed/duplex', () => 'ethtool $_if'),
                  _cmd('RX/TX Stats', () => 'ip -s link show $_if'),
                  _cmd('Socket stats', () => 'ss -tuln'),
                  _cmd('Bring up', () => 'sudo ip link set $_if up'),
                  _cmd('Bring down', () => 'sudo ip link set $_if down'),
                ],
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.route,
          title: 'Connectivity / IP / Routing',
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
                      controller: _ping,
                      decoration: const InputDecoration(
                        labelText: 'IP Address',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  _cmd('Ping', () => 'ping -I $_if -c 4 ${_ping.text}'),
                  _cmd('IP route', () => 'ip route show'),
                  _cmd('ARP Table', () => 'arp -n'),
                  _cmd('Interface errors', () => 'cat /proc/net/dev'),
                  _cmd(
                    'DHCP renew',
                    () => 'sudo dhclient -r $_if && sudo dhclient $_if',
                  ),
                ],
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.hub_outlined,
          title: 'MDIO / PHY',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _cmd('MDIO List', () => 'ls -al /sys/bus/mdio_bus/devices/'),
              _cmd('net List', () => 'ls -al /sys/class/net/'),
              _cmd(
                'PHY/MDIO Logs',
                () => 'sudo dmesg | grep -i -E "phy|mdio|eqos|rgmii"',
              ),
              _cmd('PHY ID', () => 'cat /sys/class/net/$_if/phydev/phy_id'),
            ],
          ),
        ),
      ],
    );
  }
}
