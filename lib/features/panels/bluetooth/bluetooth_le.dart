import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sanc_term_theme.dart';
import '../../../services/ble_service.dart';
import '../../../shared/widgets/panel.dart';
import 'providers/ble_notifier.dart';
import 'widgets/ble_gatt_control.dart';

class BlePanel extends ConsumerStatefulWidget {
  const BlePanel({super.key});

  @override
  ConsumerState<BlePanel> createState() => _BlePanelState();
}

class _BlePanelState extends ConsumerState<BlePanel> {
  final _filter = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Re-filter the list as the query changes.
    _filter.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bleNotifierProvider);
    final notifier = ref.read(bleNotifierProvider.notifier);

    final query = _filter.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? state.devices
        : state.devices
            .where(
              (d) =>
                  (d.name ?? '').toLowerCase().contains(query) ||
                  d.deviceId.toLowerCase().contains(query),
            )
            .toList();

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
                icon: Icons.devices,
                label: 'Connected',
                tooltipStr: 'List devices already connected to this PC. Use when '
                    'a device stays connected after an app restart and so does '
                    'not appear in a scan.',
                onPressed: () => notifier.loadSystemDevices(),
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
              PanelActionButton(
                icon: Icons.sync,
                label: 'Reconnect',
                tooltipStr: 'Drop & reconnect, re-discover services and '
                    're-enable notifications. Use after power-cycling the board '
                    '(Windows keeps a rebooted device "connected").',
                onPressed: (state.isConnected || state.selectedId != null)
                    ? () => notifier.reconnect()
                    : null,
              ),
            ],
          ),
        ),
        MyPanelBody(
          icon: Icons.devices,
          title: 'Discovered Devices',
          subtitle: query.isEmpty
              ? '${state.devices.length} found'
              : '${filtered.length} of ${state.devices.length} match',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 40,
                child: TextField(
                  controller: _filter,
                  decoration: InputDecoration(
                    labelText: 'Filter',
                    hintText: 'Filter by name or ID…',
                    prefixIcon: const Icon(Icons.filter_list, size: 18),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            tooltip: 'Clear filter',
                            onPressed: _filter.clear,
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _DeviceList(
                devices: filtered,
                totalCount: state.devices.length,
                isScanning: state.isScanning,
                selectedId: state.selectedId,
                connectedId: state.connectedId,
                onSelect: notifier.select,
              ),
            ],
          ),
        ),
        // Per-characteristic GATT control + received-data view. Shares the
        // keepAlive notifier with the Thingy:53 panel; this panel already has a
        // device list, so its own connect controls are hidden here.
        const BleGattControl(),
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
  const _DeviceList({
    required this.devices,
    required this.totalCount,
    required this.isScanning,
    required this.selectedId,
    required this.connectedId,
    required this.onSelect,
  });

  /// Devices to show (already filtered).
  final List<BleDevice> devices;

  /// Total discovered before filtering — distinguishes "no matches" from
  /// "nothing discovered yet".
  final int totalCount;
  final bool isScanning;
  final String? selectedId;
  final String? connectedId;
  final void Function(String deviceId) onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (devices.isEmpty) {
      final msg = totalCount == 0
          ? (isScanning ? 'Scanning…' : 'No devices. Press Scan to search.')
          : 'No devices match the filter.';
      return Text(msg, style: TextStyle(fontSize: 12, color: c.muted));
    }
    return Column(
      children: [
        for (final d in devices)
          _DeviceRow(
            device: d,
            selected: d.deviceId == selectedId,
            connected: d.deviceId == connectedId,
            onTap: () => onSelect(d.deviceId),
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
