import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/utils/my_utils.dart';
import 'package:sanc_term/features/panels/bluetooth/providers/ble_notifier.dart';

/// Nordic UART Service (NUS) UUIDs — the usual control channel on nRF / Thingy
/// firmware. The central (this app) *writes* to [rx]; the device *notifies* on
/// [tx]. Reference these instead of pasting UUID strings into buttons.
class NusUuids {
  NusUuids._();

  static const service = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const rx = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const tx = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';
}

/// True while a BLE device is connected. Watch this to enable/disable BLE
/// control buttons, e.g.:
///
/// ```dart
/// final connected = ref.watch(bleConnectedProvider);
/// PanelActionButton(onPressed: connected ? () => ... : null, ...);
/// ```
final bleConnectedProvider = Provider<bool>(
  (ref) => ref.watch(bleNotifierProvider.select((s) => s.isConnected)),
);

/// Fire-and-forget write of raw [bytes] to [characteristic] on [service] over
/// the connected BLE device. Warns via snackbar if nothing is connected.
/// Write-with/without-response is chosen from the characteristic's properties.
void sendBleWrite(
  WidgetRef ref,
  BuildContext context,
  String service,
  String characteristic,
  Uint8List bytes,
) {
  if (!ref.read(bleNotifierProvider).isConnected) {
    myUtils.showErrorSnackbar(context, 'No connected BLE device');
    return;
  }
  ref
      .read(bleNotifierProvider.notifier)
      .writeChar(service, characteristic, bytes);
}

/// Sends [command] as UTF-8 to a characteristic (NUS RX by default), appending
/// [terminator] (newline by default, like a shell line). The BLE analogue of
/// `sendBoardCommand` — a Thingy control button becomes a one-liner:
///
/// ```dart
/// PanelActionButton(
///   label: 'LED On',
///   onPressed: () => sendBleCommand(ref, context, 'led on'),
///   ...
/// );
/// ```
void sendBleCommand(
  WidgetRef ref,
  BuildContext context,
  String command, {
  String service = NusUuids.service,
  String characteristic = NusUuids.rx,
  String terminator = '\n',
}) {
  final payload = '${command.trimRight()}$terminator';
  sendBleWrite(
    ref,
    context,
    service,
    characteristic,
    Uint8List.fromList(utf8.encode(payload)),
  );
}
