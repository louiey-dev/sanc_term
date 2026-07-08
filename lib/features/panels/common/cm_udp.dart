import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sanc_term_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/panel.dart';
import 'providers/udp_notifier.dart';

class CmUdpPanel extends ConsumerStatefulWidget {
  const CmUdpPanel({super.key});

  @override
  ConsumerState<CmUdpPanel> createState() => _CmUdpPanelState();
}

class _CmUdpPanelState extends ConsumerState<CmUdpPanel> {
  final _ip = TextEditingController(text: '127.0.0.1');
  final _port = TextEditingController(text: '8888');
  final _localPort = TextEditingController(text: '8888');
  final _message = TextEditingController();

  @override
  void dispose() {
    _ip.dispose();
    _port.dispose();
    _localPort.dispose();
    _message.dispose();
    super.dispose();
  }

  void _send() {
    final port = int.tryParse(_port.text.trim());
    if (port == null || port < 1 || port > 65535) {
      _snack('Enter a valid target port (1–65535)');
      return;
    }
    ref.read(udpNotifierProvider.notifier).send(
          _ip.text.trim(),
          port,
          _message.text,
        );
  }

  void _toggleListen() {
    final port = int.tryParse(_localPort.text.trim());
    if (port == null || port < 0 || port > 65535) {
      _snack('Enter a valid local port (0–65535)');
      return;
    }
    ref.read(udpNotifierProvider.notifier).toggleListen(port);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(udpNotifierProvider);
    final c = context.colors;

    return MyPanel(
      icon: Icons.wifi_tethering,
      panelTitle: 'UDP',
      panelSubtitle: 'Send and receive UDP datagrams',
      panelActions: [
        StatusBadge(
          label: state.listening ? 'LISTENING :${state.boundPort}' : 'IDLE',
          color: state.listening ? c.primary : c.muted,
        ),
      ],
      children: [
        MyPanelBody(
          icon: Icons.dns,
          title: 'Endpoint',
          subtitle: 'Target host/port to send to, and a local port to listen on',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _field(_ip, 'Target IP / host', width: 180),
                  _field(
                    _port,
                    'Port',
                    width: 90,
                    numeric: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _field(
                    _localPort,
                    'Local port',
                    width: 120,
                    numeric: true,
                    enabled: !state.listening,
                  ),
                  PanelActionButton(
                    icon: state.listening ? Icons.stop : Icons.hearing,
                    label: state.listening ? 'Stop' : 'Listen',
                    tooltipStr: state.listening
                        ? 'Stop receiving'
                        : 'Bind the local port and receive datagrams',
                    onPressed: _toggleListen,
                  ),
                ],
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.send,
          title: 'Send',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _message,
                minLines: 2,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Payload to send…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              PanelActionButton(
                icon: Icons.send,
                label: 'Send',
                tooltipStr: 'Send the message to the target host:port',
                onPressed: _send,
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.receipt_long,
          title: 'Traffic Log',
          subtitle: '${state.log.length} messages',
          trailing: PanelActionButton(
            icon: Icons.clear_all,
            label: 'Clear',
            tooltipStr: 'Clear the traffic log',
            onPressed: () => ref.read(udpNotifierProvider.notifier).clearLog(),
          ),
          child: _TrafficLog(log: state.log),
        ),
        if (state.error != null)
          MyPanelBody(
            icon: Icons.error_outline,
            title: 'Last Error',
            child: SelectableText(
              state.error!,
              style: TextStyle(fontSize: 11, color: c.destructive),
            ),
          ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required double width,
    bool numeric = false,
    bool enabled = true,
  }) {
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: numeric ? TextInputType.number : null,
        inputFormatters:
            numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

class _TrafficLog extends StatelessWidget {
  const _TrafficLog({required this.log});

  final List<UdpLogEntry> log;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (log.isEmpty) {
      return Text(
        'No traffic yet.',
        style: TextStyle(fontSize: 12, color: c.muted),
      );
    }
    // Newest first.
    final entries = log.reversed.toList();
    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: entries.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: c.border),
        itemBuilder: (_, i) => _LogRow(entry: entries[i]),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});

  final UdpLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = entry.time;
    final ts =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    final color = entry.outgoing ? c.primary : c.foreground;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            entry.outgoing ? Icons.north_east : Icons.south_west,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$ts  ${entry.outgoing ? '→' : '←'} ${entry.peer}',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'Consolas',
                    color: c.muted,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  entry.text,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Consolas',
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
