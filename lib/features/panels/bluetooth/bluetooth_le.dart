import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sanc_term_theme.dart';
import '../../../services/ble_service.dart';
import '../../../shared/widgets/panel.dart';
import 'providers/ble_notifier.dart';

class BlePanel extends ConsumerWidget {
  const BlePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bleNotifierProvider);
    final notifier = ref.read(bleNotifierProvider.notifier);

    final canConnect =
        state.selectedId != null &&
        !state.connecting &&
        state.selectedId != state.connectedId;

    return MyPanel(
      icon: Icons.bluetooth,
      panelTitle: 'Bluetooth LE',
      panelSubtitle: 'Bluetooth LE quick access panel',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.bluetooth,
          title: 'BLE Commands',
          subtitle: _status(state),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PanelActionButton(
                icon: state.isScanning ? Icons.stop : Icons.bluetooth_searching,
                label: state.isScanning ? 'Stop' : 'Scan',
                tooltipStr: 'Scan for nearby BLE devices',
                onPressed: () => notifier.toggleScan(),
              ),
              PanelActionButton(
                icon: Icons.bluetooth_connected,
                label: 'Connect',
                tooltipStr: 'Connect to the selected device',
                onPressed: canConnect ? () => notifier.connect() : null,
              ),
              PanelActionButton(
                icon: Icons.bluetooth_disabled,
                label: 'Disconnect',
                tooltipStr: 'Disconnect from the connected device',
                onPressed: state.isConnected ? () => notifier.disconnect() : null,
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.devices,
          title: 'Discovered Devices',
          subtitle: '${state.devices.length} found',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isScanning) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
              ],
              PanelActionButton(
                icon: Icons.clear_all,
                label: 'Clear',
                tooltipStr: 'Clear the discovered device list',
                onPressed: state.devices.isEmpty ? null : notifier.clearDevices,
              ),
            ],
          ),
          child: _DeviceList(state: state, notifier: notifier),
        ),
        if (state.error != null)
          MyPanelBody(
            icon: Icons.error_outline,
            title: 'Last Error',
            child: SelectableText(
              state.error!,
              style: TextStyle(fontSize: 11, color: context.colors.destructive),
            ),
          ),
      ],
    );
  }

  String _status(BleState state) {
    final radio = state.availability?.name ?? 'unknown';
    if (state.connecting) return 'Radio: $radio · connecting…';
    if (state.isConnected) return 'Radio: $radio · connected';
    return 'Radio: $radio · not connected';
  }
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.state, required this.notifier});

  final BleState state;
  final BleNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (state.devices.isEmpty) {
      return Text(
        state.isScanning ? 'Scanning…' : 'No devices. Press Scan to search.',
        style: TextStyle(fontSize: 12, color: c.muted),
      );
    }
    return Column(
      children: [
        for (final d in state.devices)
          _DeviceRow(
            device: d,
            selected: d.deviceId == state.selectedId,
            connected: d.deviceId == state.connectedId,
            onTap: () => notifier.select(d.deviceId),
          ),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.selected,
    required this.connected,
    required this.onTap,
  });

  final BleDevice device;
  final bool selected;
  final bool connected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final name = (device.name?.isNotEmpty ?? false) ? device.name! : '(unnamed)';
    final rssi = device.rssi;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? c.primary : c.border),
        ),
        child: Row(
          children: [
            Icon(
              connected ? Icons.bluetooth_connected : Icons.bluetooth,
              size: 16,
              color: connected ? c.primary : c.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.foreground,
                    ),
                  ),
                  Text(
                    device.deviceId,
                    style: TextStyle(fontSize: 10, color: c.muted),
                  ),
                ],
              ),
            ),
            if (connected)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'connected',
                  style: TextStyle(fontSize: 10, color: c.primary),
                ),
              ),
            if (rssi != null)
              Text(
                '$rssi dBm',
                style: TextStyle(fontSize: 10, color: c.muted),
              ),
          ],
        ),
      ),
    );
  }
}
