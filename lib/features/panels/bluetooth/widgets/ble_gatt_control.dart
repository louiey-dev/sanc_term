import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/sanc_term_theme.dart';
import '../../../../services/ble_service.dart';
import '../../../../shared/widgets/common.dart';
import '../../../../shared/widgets/panel.dart';
import '../providers/ble_notifier.dart';

/// Reusable BLE GATT control, driven by the shared [bleNotifierProvider]
/// (keepAlive), so the Bluetooth LE panel and the Thingy:53 panel act on the
/// same connection. Renders per-characteristic subscribe/read/write and a
/// received-data view (text or hex) for the selected characteristic.
///
/// Set [showConnect] to include a compact scan/connect row — the Thingy:53
/// panel needs it; the Bluetooth LE panel already has its own device list.
class BleGattControl extends ConsumerStatefulWidget {
  const BleGattControl({super.key, this.showConnect = false});

  final bool showConnect;

  @override
  ConsumerState<BleGattControl> createState() => _BleGattControlState();
}

class _BleGattControlState extends ConsumerState<BleGattControl> {
  final _rxScroll = ScrollController();
  final _write = TextEditingController();
  final _mtu = TextEditingController(text: '247');

  /// Received-data render mode: false = text (UTF-8), true = hex.
  bool _hexMode = false;

  /// Interpret the write field as hex bytes (true) or UTF-8 text (false).
  bool _writeHex = false;

  @override
  void dispose() {
    _rxScroll.dispose();
    _write.dispose();
    _mtu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bleNotifierProvider);
    final sections = <Widget>[
      if (widget.showConnect) _connectSection(state),
      _gattSection(state),
      _dataSection(state),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < sections.length; i++) ...[
          sections[i],
          if (i < sections.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  // --- Compact connect -------------------------------------------------------

  Widget _connectSection(BleState state) {
    final notifier = ref.read(bleNotifierProvider.notifier);
    final canConnect = state.selectedId != null &&
        !state.connecting &&
        state.selectedId != state.connectedId;
    return MyPanelBody(
      icon: Icons.bluetooth,
      title: 'BLE Connection',
      subtitle: _status(state),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PanelActionButton(
            icon: state.isScanning ? Icons.stop : Icons.bluetooth_searching,
            label: state.isScanning ? 'Stop' : 'Scan',
            tooltipStr: 'Scan for nearby BLE devices',
            onPressed: notifier.toggleScan,
          ),
          PanelActionButton(
            icon: Icons.devices,
            label: 'Connected',
            tooltipStr: 'List devices already connected to this PC. Use when a '
                'device stays connected after an app restart and so does not '
                'appear in a scan.',
            onPressed: notifier.loadSystemDevices,
          ),
          _deviceDropdown(state, notifier),
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
            onPressed: state.isConnected ? notifier.disconnect : null,
          ),
          PanelActionButton(
            icon: Icons.sync,
            label: 'Reconnect',
            tooltipStr: 'Drop & reconnect, re-discover services and re-enable '
                'notifications. Use after power-cycling the board (Windows keeps '
                'a rebooted device "connected").',
            onPressed: (state.isConnected || state.selectedId != null)
                ? notifier.reconnect
                : null,
          ),
        ],
      ),
    );
  }

  Widget _deviceDropdown(BleState state, BleNotifier notifier) {
    final value = state.devices.any((d) => d.deviceId == state.selectedId)
        ? state.selectedId
        : null;
    return buildDropdown<String>(
      context,
      value: value,
      hint: state.devices.isEmpty ? 'No devices' : 'Select device',
      width: 220,
      items: [
        for (final d in state.devices)
          DropdownMenuItem(
            value: d.deviceId,
            child: Text(
              (d.name?.isNotEmpty ?? false) ? d.name! : d.deviceId,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: state.devices.isEmpty
          ? null
          : (v) {
              if (v != null) notifier.select(v);
            },
    );
  }

  // --- GATT tree -------------------------------------------------------------

  Widget _gattSection(BleState state) {
    final notifier = ref.read(bleNotifierProvider.notifier);
    return MyPanelBody(
      icon: Icons.account_tree,
      title: 'GATT Services',
      subtitle: state.isConnected
          ? '${state.services.length} services'
          : 'Not connected',
      trailing: state.isConnected
          ? PanelActionButton(
              icon: Icons.refresh,
              label: 'Rediscover',
              tooltipStr: 'Re-run service discovery only',
              onPressed: notifier.rediscover,
            )
          : null,
      child: !state.isConnected
          ? Text(
              'Connect to a device to browse services.',
              style: TextStyle(fontSize: 12, color: context.colors.muted),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _mtuRow(state, notifier),
                const SizedBox(height: 12),
                if (state.services.isEmpty)
                  Text(
                    'Discovering services…',
                    style: TextStyle(fontSize: 12, color: context.colors.muted),
                  )
                else
                  for (final s in state.services) _service(state, notifier, s),
              ],
            ),
    );
  }

  Widget _mtuRow(BleState state, BleNotifier notifier) {
    final c = context.colors;
    final current = state.mtu;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 90,
          height: 40,
          child: TextField(
            controller: _mtu,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'Consolas'),
            decoration: const InputDecoration(
              labelText: 'MTU',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
        PanelActionButton(
          icon: Icons.tune,
          label: 'Set MTU',
          tooltipStr: 'Request ATT MTU (usable payload = MTU − 3). Best-effort; '
              'the OS/peer may cap it. On Windows the MTU is fixed at connection '
              'time, so this reports the negotiated value.',
          onPressed: () async {
            final v = int.tryParse(_mtu.text.trim());
            if (v == null) return;
            final result = await notifier.requestMtu(v);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                content: Text(
                  result == null
                      ? 'MTU request failed'
                      : 'MTU negotiated: $result (payload ${result - 3})',
                ),
              ),
            );
          },
        ),
        Text(
          current == null
              ? 'Negotiated: — '
              : 'Negotiated: $current (payload ${current - 3})',
          style: TextStyle(fontSize: 11, color: c.muted),
        ),
      ],
    );
  }

  Widget _service(BleState state, BleNotifier notifier, BleGattService s) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            'Service ${_shortUuid(s.uuid)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Consolas',
              color: c.muted,
            ),
          ),
        ),
        for (final ch in s.characteristics) _charRow(state, notifier, s, ch),
      ],
    );
  }

  Widget _charRow(
    BleState state,
    BleNotifier notifier,
    BleGattService s,
    BleCharacteristic ch,
  ) {
    final c = context.colors;
    final props = ch.properties;
    final canNotify = props.contains(BleCharProperty.notify) ||
        props.contains(BleCharProperty.indicate);
    final canRead = props.contains(BleCharProperty.read);
    final subscribed = state.subscribed.contains(ch.uuid);
    final selected = state.selectedChar == ch.uuid;
    final rxCount = state.receivedFor(ch.uuid).length;

    return InkWell(
      onTap: () => notifier.selectChar(ch.uuid),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? c.primary : c.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _shortUuid(ch.uuid),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Consolas',
                      fontWeight: FontWeight.w600,
                      color: c.foreground,
                    ),
                  ),
                  Text(
                    rxCount > 0
                        ? '${_propLabel(props)} · $rxCount pkts'
                        : _propLabel(props),
                    style: TextStyle(
                      fontSize: 10,
                      color: rxCount > 0 ? c.primary : c.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (canRead)
              _iconAction(
                Icons.download,
                'Read',
                () => notifier.readChar(s.uuid, ch.uuid),
              ),
            if (canNotify)
              _iconAction(
                subscribed ? Icons.notifications_active : Icons.notifications_none,
                subscribed ? 'Unsubscribe' : 'Subscribe',
                () => subscribed
                    ? notifier.unsubscribeChar(s.uuid, ch.uuid)
                    : notifier.subscribeChar(s.uuid, ch.uuid),
                active: subscribed,
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconAction(IconData icon, String tip, VoidCallback onTap,
      {bool active = false}) {
    final c = context.colors;
    return Tooltip(
      message: tip,
      child: IconButton(
        icon: Icon(icon, size: 16),
        color: active ? c.primary : c.muted,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: onTap,
      ),
    );
  }

  // --- Write + received data (selected characteristic) -----------------------

  Widget _dataSection(BleState state) {
    final notifier = ref.read(bleNotifierProvider.notifier);
    final c = context.colors;
    final sel = state.selectedChar;
    final selChar = sel == null ? null : _findChar(state, sel);
    final canWrite = selChar != null &&
        (selChar.properties.contains(BleCharProperty.write) ||
            selChar.properties.contains(BleCharProperty.writeWithoutResponse));
    final chunks = sel == null ? const <Uint8List>[] : state.receivedFor(sel);
    // Total across every characteristic — if this climbs while the selected
    // char stays at 0, the device is notifying on a different characteristic.
    final totalPkts =
        state.received.values.fold<int>(0, (n, l) => n + l.length);

    // Keep the newest data visible once this frame lays out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rxScroll.hasClients) {
        _rxScroll.jumpTo(_rxScroll.position.maxScrollExtent);
      }
    });

    return MyPanelBody(
      icon: Icons.swap_vert,
      title: 'Characteristic Data',
      subtitle: sel == null
          ? 'Select a characteristic above · $totalPkts pkts on all chars'
          : '${_shortUuid(sel)} · ${state.byteCountFor(sel)} bytes · '
              'max payload ${state.maxPayloadFor(sel)} B · '
              '$totalPkts pkts on all chars',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeSelector(hex: _hexMode, onChanged: (v) => setState(() => _hexMode = v)),
          const SizedBox(width: 8),
          PanelActionButton(
            icon: Icons.clear_all,
            label: 'Clear',
            tooltipStr: 'Clear this characteristic buffer',
            onPressed: chunks.isEmpty ? null : () => notifier.clearReceived(sel),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canWrite) ...[
            Row(
              children: [
                _WriteFmtToggle(
                  hex: _writeHex,
                  onChanged: (v) => setState(() => _writeHex = v),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _write,
                      style: const TextStyle(fontFamily: 'Consolas'),
                      decoration: InputDecoration(
                        hintText: _writeHex ? 'AA BB CC' : 'text to send',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _send(notifier, sel!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PanelActionButton(
                  icon: Icons.send,
                  label: 'Write',
                  tooltipStr: 'Write to the selected characteristic',
                  onPressed: () => _send(notifier, sel!),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Container(
            width: double.infinity,
            height: 170,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: c.border),
            ),
            child: chunks.isEmpty
                ? Text(
                    sel == null
                        ? 'No characteristic selected.'
                        : 'No data yet — Subscribe or Read.',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  )
                : SingleChildScrollView(
                    controller: _rxScroll,
                    child: SelectableText(
                      _format(chunks, _hexMode),
                      style: TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                        color: c.foreground,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _send(BleNotifier notifier, String charUuid) {
    final service = _serviceOf(ref.read(bleNotifierProvider), charUuid);
    if (service == null) return;
    final bytes = _parseWrite(_write.text, _writeHex);
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid hex — use pairs like "AA BB".')),
      );
      return;
    }
    if (bytes.isEmpty) return;
    notifier.writeChar(service, charUuid, bytes);
    _write.clear();
  }

  // --- helpers ---------------------------------------------------------------

  String _status(BleState state) {
    final radio = state.availability?.name ?? 'unknown';
    if (state.connecting) return 'Radio: $radio · connecting…';
    if (state.isConnected) return 'Radio: $radio · connected';
    return 'Radio: $radio · not connected';
  }

  BleCharacteristic? _findChar(BleState state, String charUuid) {
    for (final s in state.services) {
      for (final ch in s.characteristics) {
        if (ch.uuid == charUuid) return ch;
      }
    }
    return null;
  }

  String? _serviceOf(BleState state, String charUuid) {
    for (final s in state.services) {
      for (final ch in s.characteristics) {
        if (ch.uuid == charUuid) return s.uuid;
      }
    }
    return null;
  }

  static String _format(List<Uint8List> chunks, bool hex) {
    if (hex) {
      final sb = StringBuffer();
      for (final chunk in chunks) {
        for (final b in chunk) {
          sb.write(b.toRadixString(16).padLeft(2, '0').toUpperCase());
          sb.write(' ');
        }
      }
      return sb.toString().trimRight();
    }
    final bytes = <int>[];
    for (final chunk in chunks) {
      bytes.addAll(chunk);
    }
    // allowMalformed keeps non-UTF-8 payloads from throwing (shown as U+FFFD).
    return utf8.decode(bytes, allowMalformed: true);
  }

  /// Parses the write field. Text mode → UTF-8 bytes. Hex mode → bytes from
  /// pairs (spaces optional); returns null on malformed hex.
  static Uint8List? _parseWrite(String input, bool hex) {
    if (!hex) return Uint8List.fromList(utf8.encode(input));
    final clean = input.replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return Uint8List(0);
    if (clean.length.isOdd || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(clean)) {
      return null;
    }
    final out = <int>[];
    for (var i = 0; i < clean.length; i += 2) {
      out.add(int.parse(clean.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(out);
  }

  static const _baseSuffix = '-0000-1000-8000-00805f9b34fb';

  static String _shortUuid(String uuid) {
    final u = uuid.toLowerCase();
    if (u.startsWith('0000') && u.endsWith(_baseSuffix)) {
      return '0x${u.substring(4, 8).toUpperCase()}';
    }
    return u.split('-').first;
  }

  static String _propLabel(List<BleCharProperty> props) {
    final parts = <String>[];
    if (props.contains(BleCharProperty.read)) parts.add('Read');
    if (props.contains(BleCharProperty.write)) parts.add('Write');
    if (props.contains(BleCharProperty.writeWithoutResponse)) parts.add('WriteNR');
    if (props.contains(BleCharProperty.notify)) parts.add('Notify');
    if (props.contains(BleCharProperty.indicate)) parts.add('Indicate');
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}

/// Text ⇄ Hex toggle for the received-data view.
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.hex, required this.onChanged});

  final bool hex;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
        segments: const [
          ButtonSegment(value: false, label: Text('Text')),
          ButtonSegment(value: true, label: Text('Hex')),
        ],
        selected: {hex},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

/// Text ⇄ Hex toggle for interpreting the write field.
class _WriteFmtToggle extends StatelessWidget {
  const _WriteFmtToggle({required this.hex, required this.onChanged});

  final bool hex;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        segments: const [
          ButtonSegment(value: false, label: Text('Txt')),
          ButtonSegment(value: true, label: Text('Hex')),
        ],
        selected: {hex},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
