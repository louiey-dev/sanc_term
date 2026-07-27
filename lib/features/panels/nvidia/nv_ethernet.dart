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
  final _pingDuration = TextEditingController(text: '1000');
  final _pingCount = TextEditingController(text: '0');
  final _serverIp = TextEditingController(text: '192.168.1.2');
  final _slaveIp = TextEditingController(text: '192.168.1.7');

  @override
  void dispose() {
    _link.dispose();
    _ping.dispose();
    _pingDuration.dispose();
    _pingCount.dispose();
    _serverIp.dispose();
    _slaveIp.dispose();
    super.dispose();
  }

  String get _if => _link.text;

  // [command] is evaluated lazily so it always reflects the current interface
  // ([_if]) and ping target, even if the widget hasn't rebuilt since selection.
  PanelActionButton _cmd(
    String label,
    String Function() command, {
    String? tip,
  }) => PanelActionButton(
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
                  _cmd(
                    'Interface State',
                    () => 'cat /sys/class/net/$_if/operstate',
                  ),
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
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: TextField(
                      controller: _pingDuration,
                      decoration: const InputDecoration(
                        labelText: 'Seconds',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: TextField(
                      controller: _pingCount,
                      decoration: const InputDecoration(
                        labelText: 'Count',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  _cmd(
                    'Ping',
                    () =>
                        'ping -I $_if -i ${_pingDuration.text} -c ${_pingCount.text} ${_ping.text}',
                  ),
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
        MyPanelBody(
          icon: Icons.hub_outlined,
          title: 'iperf / ethtool',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  const SelectableText(
                    '''iperf3 must be installed on both ends of the test.
Use the "iperf3 -s" command on the server side. ( sudo apt update && sudo apt install iperf3 )\n
Step 1 : Maximize Jetson Clocks & Hardware Performance''',
                  ),
                  _cmd(
                    'Max Clocks',
                    () => 'sudo nvpmodel -m 0 && sudo jetson_clocks',
                    tip:
                        'Maximizes clocks and performance for all hardware blocks',
                  ),
                  const SelectableText('''Step 2 : Run the Throughput Pipelines
Your host PC is server side, and Jetson is client side. Run the following commands on both ends
On the host PC (server side):
iperf3 -s
On the Jetson (client side):
iperf3 -c <host_ip_address> -B <jetson_ip_address of eno1 or eth1>'''),
                  Row(
                    spacing: 8,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _cmd(
                        'iperf3 Server',
                        () => 'iperf3 -s',
                        tip: 'Run this on the host PC (server side)',
                      ),
                      VerticalDivider(width: 1, color: Colors.grey.shade400),
                      SizedBox(
                        width: 140,
                        height: 30,
                        child: TextField(
                          controller: _serverIp,
                          decoration: const InputDecoration(
                            labelText: 'Host IP',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        height: 30,
                        child: TextField(
                          controller: _slaveIp,
                          decoration: const InputDecoration(
                            labelText: 'Client IP',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      _cmd(
                        'iperf3 Client',
                        () => 'iperf3 -c ${_serverIp.text} -B ${_slaveIp.text}',
                        tip: 'Run this on the Jetson (client side)',
                      ),
                    ],
                  ),
                  const SelectableText(
                    '''\nYou can check your port speed via sudo ethtool eth1/eno1 | grep -E "Speed|Duplex|Link detected"
For the best results, please make sure whether unused port has been down via sudo ifconfig eth1/eno1 down''',
                    style: TextStyle(fontSize: 14, color: Colors.yellow),
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
