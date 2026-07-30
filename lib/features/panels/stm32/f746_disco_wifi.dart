import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/common.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// STM32 F746 Wi-Fi, TCP/IP & HTTP Panel / Sub Panel.
/// Provides control for ESP32 Wi-Fi (status, ver, scan, connect, disconnect, ap, ip, mode, send, demo),
/// TCPIP (connect, send, recv, close), and HTTP (get, post) commands.
class F746WifiPanel extends ConsumerStatefulWidget {
  final bool standalone;

  const F746WifiPanel({super.key, this.standalone = true});

  @override
  ConsumerState<F746WifiPanel> createState() => _F746WifiPanelState();
}

class _F746WifiPanelState extends ConsumerState<F746WifiPanel> {
  // WiFi Controllers
  final _wifiSsid = TextEditingController(text: 'MyWiFi');
  final _wifiPass = TextEditingController(text: '');
  String _wifiMode = '1';
  final _wifiAtCmd = TextEditingController(text: 'AT+GMR');
  final _wifiDemoSsid = TextEditingController(text: '');
  final _wifiDemoPass = TextEditingController(text: '');
  final _wifiDemoServer = TextEditingController(text: '192.168.1.100');
  final _wifiDemoPort = TextEditingController(text: '8080');

  // TCP Controllers
  final _tcpHost = TextEditingController(text: '192.168.1.100');
  final _tcpPort = TextEditingController(text: '8080');
  final _tcpMsg = TextEditingController(text: 'Hello World');
  final _tcpRecvTimeout = TextEditingController(text: '5000');

  // UDP Controllers
  final _udpHost = TextEditingController(text: '192.168.1.100');
  final _udpPort = TextEditingController(text: '5000');
  final _udpMsg = TextEditingController(text: 'Hello UDP');
  final _udpRecvTimeout = TextEditingController(text: '5000');
  final _udpSendToHost = TextEditingController(text: '192.168.1.100');
  final _udpSendToPort = TextEditingController(text: '5000');
  final _udpSendToMsg = TextEditingController(text: 'Hello UDP Direct');

  // HTTP Controllers
  final _httpGetHost = TextEditingController(text: 'httpbin.org');
  final _httpGetPath = TextEditingController(text: '/get');
  final _httpGetPort = TextEditingController(text: '80');
  final _httpPostHost = TextEditingController(text: 'httpbin.org');
  final _httpPostPath = TextEditingController(text: '/post');
  final _httpPostPort = TextEditingController(text: '80');
  final _httpPostBody = TextEditingController(text: '{"key":"value"}');

  @override
  void dispose() {
    _wifiSsid.dispose();
    _wifiPass.dispose();
    _wifiAtCmd.dispose();
    _wifiDemoSsid.dispose();
    _wifiDemoPass.dispose();
    _wifiDemoServer.dispose();
    _wifiDemoPort.dispose();

    _tcpHost.dispose();
    _tcpPort.dispose();
    _tcpMsg.dispose();
    _tcpRecvTimeout.dispose();

    _udpHost.dispose();
    _udpPort.dispose();
    _udpMsg.dispose();
    _udpRecvTimeout.dispose();
    _udpSendToHost.dispose();
    _udpSendToPort.dispose();
    _udpSendToMsg.dispose();

    _httpGetHost.dispose();
    _httpGetPath.dispose();
    _httpGetPort.dispose();
    _httpPostHost.dispose();
    _httpPostPath.dispose();
    _httpPostPort.dispose();
    _httpPostBody.dispose();

    super.dispose();
  }

  void _send(String cmd) => sendBoardCommand(ref, context, cmd);

  PanelActionButton _btn(
    String label,
    String cmd,
    String tip, [
    IconData? icon,
  ]) => PanelActionButton(
    icon: icon ?? Icons.bolt,
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
        icon: Icons.wifi,
        panelTitle: 'F746 Wi-Fi Panel',
        panelSubtitle:
            'ESP32 Wi-Fi, TCP/IP & HTTP commands for STM32F746',
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
      // 1) WiFi Commands
      MyPanelBody(
        icon: Icons.wifi,
        title: 'WiFi — ESP32 Wi-Fi Commands',
        subtitle: 'Status, AP scan/connect, mode selection, raw AT & test demo',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Wi-Fi Quick Commands'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn(
                  'Status',
                  'wifi status',
                  'Show Wi-Fi module status',
                  Icons.info_outline,
                ),
                _btn(
                  'Version',
                  'wifi ver',
                  'Get ESP32 AT version (AT+GMR)',
                  Icons.verified,
                ),
                _btn(
                  'Scan APs',
                  'wifi scan',
                  'Scan Wi-Fi access points (AT+CWLAP)',
                  Icons.radar,
                ),
                _btn(
                  'Get AP',
                  'wifi ap',
                  'Get current connected AP (AT+CWJAP?)',
                  Icons.router,
                ),
                _btn(
                  'Get IP',
                  'wifi ip',
                  'Get IP and MAC address (AT+CIFSR)',
                  Icons.pin_drop,
                ),
                _btn(
                  'Disconnect',
                  'wifi disconnect',
                  'Disconnect from AP (AT+CWQAP)',
                  Icons.wifi_off,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Wi-Fi Mode Selection'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                buildDropdown<String>(
                  context,
                  value: _wifiMode,
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('Station (1)')),
                    DropdownMenuItem(value: '2', child: Text('SoftAP (2)')),
                    DropdownMenuItem(value: '3', child: Text('STA+AP (3)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _wifiMode = v);
                  },
                  width: 140,
                ),
                PanelActionButton(
                  icon: Icons.settings,
                  label: 'Set Mode',
                  tooltipStr: 'wifi mode <1|2|3>',
                  onPressed: () => _send('wifi mode $_wifiMode'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Connect to AP'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_wifiSsid, 'SSID', width: 160),
                _inputField(_wifiPass, 'Password', width: 160, hint: 'optional'),
                PanelActionButton(
                  icon: Icons.wifi,
                  label: 'Connect',
                  tooltipStr: 'wifi connect <ssid> [pass]',
                  onPressed: () {
                    final ssid = _wifiSsid.text.trim();
                    final pass = _wifiPass.text.trim();
                    if (ssid.isNotEmpty) {
                      final cmd =
                          pass.isEmpty
                              ? 'wifi connect $ssid'
                              : 'wifi connect $ssid $pass';
                      _send(cmd);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Send Raw AT Command'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _wifiAtCmd,
                  'AT Command',
                  width: 220,
                  hint: 'AT+CWLAP',
                ),
                PanelActionButton(
                  icon: Icons.send,
                  label: 'Send AT',
                  tooltipStr: 'wifi send <AT_cmd>',
                  onPressed: () {
                    final cmd = _wifiAtCmd.text.trim();
                    if (cmd.isNotEmpty) {
                      _send('wifi send $cmd');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('Wi-Fi Data Demo / Test'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_wifiDemoSsid, 'SSID', width: 130),
                _inputField(_wifiDemoPass, 'Pass', width: 110),
                _inputField(_wifiDemoServer, 'Server', width: 130),
                _inputField(_wifiDemoPort, 'Port', width: 70),
                PanelActionButton(
                  icon: Icons.play_arrow,
                  label: 'Run Demo',
                  tooltipStr: 'wifi demo <ssid> <pass> [server] [port]',
                  onPressed: () {
                    final ssid = _wifiDemoSsid.text.trim();
                    final pass = _wifiDemoPass.text.trim();
                    final server = _wifiDemoServer.text.trim();
                    final port = _wifiDemoPort.text.trim();
                    if (ssid.isNotEmpty) {
                      String cmd = 'wifi demo $ssid';
                      if (pass.isNotEmpty ||
                          server.isNotEmpty ||
                          port.isNotEmpty) {
                        cmd += ' ${pass.isEmpty ? '""' : pass}';
                        if (server.isNotEmpty) {
                          cmd += ' $server';
                          if (port.isNotEmpty) {
                            cmd += ' $port';
                          }
                        }
                      }
                      _send(cmd);
                    } else {
                      _send('wifi demo');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      // 2) TCPIP Commands
      MyPanelBody(
        icon: Icons.connect_without_contact,
        title: 'TCPIP — Socket Commands',
        subtitle: 'Connect, send, receive & close TCP socket connections',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('TCP Connect & Close'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_tcpHost, 'Host', width: 180, hint: '192.168.1.100'),
                _inputField(_tcpPort, 'Port', width: 80, hint: '8080'),
                PanelActionButton(
                  icon: Icons.link,
                  label: 'TCP Connect',
                  tooltipStr: 'wifi tcpconnect <host> <port>',
                  onPressed: () {
                    final host = _tcpHost.text.trim();
                    final port = _tcpPort.text.trim();
                    if (host.isNotEmpty && port.isNotEmpty) {
                      _send('wifi tcpconnect $host $port');
                    }
                  },
                ),
                _btn(
                  'TCP Close',
                  'wifi tcpclose',
                  'Close TCP connection',
                  Icons.link_off,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('TCP Send Data'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_tcpMsg, 'Message', width: 260),
                PanelActionButton(
                  icon: Icons.send,
                  label: 'TCP Send',
                  tooltipStr: 'wifi tcpsend <msg>',
                  onPressed: () {
                    final msg = _tcpMsg.text.trim();
                    if (msg.isNotEmpty) {
                      _send('wifi tcpsend "$msg"');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('TCP Receive Data'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _tcpRecvTimeout,
                  'Timeout (ms)',
                  width: 120,
                  hint: '5000',
                ),
                PanelActionButton(
                  icon: Icons.download,
                  label: 'TCP Recv',
                  tooltipStr: 'wifi tcprecv [timeout_ms]',
                  onPressed: () {
                    final timeout = _tcpRecvTimeout.text.trim();
                    final cmd =
                        timeout.isEmpty
                            ? 'wifi tcprecv'
                            : 'wifi tcprecv $timeout';
                    _send(cmd);
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      // 3) UDP Commands
      MyPanelBody(
        icon: Icons.wifi_tethering,
        title: 'UDP — Datagram Socket Commands',
        subtitle: 'Connect, send, receive, close & sendto UDP datagram sockets',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('UDP Connect & Close'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_udpHost, 'Host', width: 180, hint: '192.168.1.100'),
                _inputField(_udpPort, 'Port', width: 80, hint: '5000'),
                PanelActionButton(
                  icon: Icons.link,
                  label: 'UDP Connect',
                  tooltipStr: 'wifi udpconnect <host> <port>',
                  onPressed: () {
                    final host = _udpHost.text.trim();
                    final port = _udpPort.text.trim();
                    if (host.isNotEmpty && port.isNotEmpty) {
                      _send('wifi udpconnect $host $port');
                    }
                  },
                ),
                _btn(
                  'UDP Close',
                  'wifi udpclose',
                  'Close UDP connection',
                  Icons.link_off,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('UDP Send Data'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_udpMsg, 'Message', width: 260),
                PanelActionButton(
                  icon: Icons.send,
                  label: 'UDP Send',
                  tooltipStr: 'wifi udpsend <msg>',
                  onPressed: () {
                    final msg = _udpMsg.text.trim();
                    if (msg.isNotEmpty) {
                      _send('wifi udpsend "$msg"');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('UDP Receive Data'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _udpRecvTimeout,
                  'Timeout (ms)',
                  width: 120,
                  hint: '5000',
                ),
                PanelActionButton(
                  icon: Icons.download,
                  label: 'UDP Recv',
                  tooltipStr: 'wifi udprecv [timeout_ms]',
                  onPressed: () {
                    final timeout = _udpRecvTimeout.text.trim();
                    final cmd =
                        timeout.isEmpty
                            ? 'wifi udprecv'
                            : 'wifi udprecv $timeout';
                    _send(cmd);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('UDP SendTo (Unconnected Direct Datagram)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_udpSendToHost, 'Host', width: 150, hint: '192.168.1.100'),
                _inputField(_udpSendToPort, 'Port', width: 70, hint: '5000'),
                _inputField(_udpSendToMsg, 'Message', width: 180, hint: 'datagram'),
                PanelActionButton(
                  icon: Icons.unarchive,
                  label: 'UDP SendTo',
                  tooltipStr: 'wifi udpsendto <host> <port> <msg>',
                  onPressed: () {
                    final host = _udpSendToHost.text.trim();
                    final port = _udpSendToPort.text.trim();
                    final msg = _udpSendToMsg.text.trim();
                    if (host.isNotEmpty && port.isNotEmpty && msg.isNotEmpty) {
                      _send('wifi udpsendto $host $port "$msg"');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      // 4) HTTP Commands
      MyPanelBody(
        icon: Icons.http,
        title: 'HTTP — Client Requests',
        subtitle: 'Execute HTTP GET and POST requests over Wi-Fi',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('HTTP GET Request'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(_httpGetHost, 'Host', width: 160, hint: 'httpbin.org'),
                _inputField(_httpGetPath, 'Path', width: 140, hint: '/get'),
                _inputField(_httpGetPort, 'Port', width: 70, hint: '80'),
                PanelActionButton(
                  icon: Icons.cloud_download,
                  label: 'HTTP GET',
                  tooltipStr: 'wifi httpget <host> <path> [port]',
                  onPressed: () {
                    final host = _httpGetHost.text.trim();
                    final path = _httpGetPath.text.trim();
                    final port = _httpGetPort.text.trim();
                    if (host.isNotEmpty && path.isNotEmpty) {
                      final cmd =
                          port.isEmpty
                              ? 'wifi httpget $host $path'
                              : 'wifi httpget $host $path $port';
                      _send(cmd);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('HTTP POST Request'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _inputField(
                  _httpPostHost,
                  'Host',
                  width: 150,
                  hint: 'httpbin.org',
                ),
                _inputField(_httpPostPath, 'Path', width: 130, hint: '/post'),
                _inputField(_httpPostPort, 'Port', width: 65, hint: '80'),
                _inputField(_httpPostBody, 'Body', width: 180, hint: 'payload'),
                PanelActionButton(
                  icon: Icons.cloud_upload,
                  label: 'HTTP POST',
                  tooltipStr: 'wifi httppost <host> <path> <body> [port]',
                  onPressed: () {
                    final host = _httpPostHost.text.trim();
                    final path = _httpPostPath.text.trim();
                    final body = _httpPostBody.text.trim();
                    final port = _httpPostPort.text.trim();
                    if (host.isNotEmpty && path.isNotEmpty) {
                      String cmd = 'wifi httppost $host $path "$body"';
                      if (port.isNotEmpty) {
                        cmd = 'wifi httppost $host $path "$body" $port';
                      }
                      _send(cmd);
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
