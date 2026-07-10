import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_ble/universal_ble.dart' as ble;

part 'ble_service.g.dart';

// Re-export the package model types the provider/UI layers need so they can
// stay on this façade and not import universal_ble directly.
typedef BleDevice = ble.BleDevice;
typedef BleGattService = ble.BleService;
typedef BleCharacteristic = ble.BleCharacteristic;
typedef BleCharProperty = ble.CharacteristicProperty;
typedef BleAvailability = ble.AvailabilityState;
typedef BleScanFilter = ble.ScanFilter;

/// Raw BLE I/O wrapper around `universal_ble` (WinRT on Windows, BlueZ on Linux,
/// CoreBluetooth on macOS/iOS, plus the Android/Web backends). No Flutter
/// widgets and no feature imports — it only powers the radio, scans, connects,
/// and pipes GATT traffic through the streams the provider layer subscribes to.
///
/// A thin façade: `universal_ble` already exposes everything as static methods
/// and broadcast streams, so this just gives the app one injectable seam (easy
/// to fake in tests) and one place to document the wire behaviour.
class BleService {
  BleService() {
    // Capture every GATT value update through the global handler and fan it out
    // on our own broadcast stream. `universal_ble`'s per-characteristic stream
    // filters on an exact deviceId string match, which the WinRT backend can
    // fail (the value event's device id differs from the connect id) — leaving
    // notifications enabled but silent. Filtering by characteristic uuid here
    // sidesteps that; we only ever hold one connection.
    ble.UniversalBle.onValueChange = (deviceId, characteristicId, value, _) {
      if (!_values.isClosed) {
        _values.add((characteristicId: characteristicId, value: value));
      }
    };
  }

  final _values = StreamController<
      ({String characteristicId, Uint8List value})>.broadcast();

  /// Devices discovered during the active scan. Emits one event per
  /// advertisement, so the same device can appear repeatedly (dedupe upstream).
  Stream<BleDevice> get scanResults => ble.UniversalBle.scanStream;

  /// Radio power / permission transitions (poweredOn, poweredOff, unauthorized…).
  Stream<BleAvailability> get availabilityChanges =>
      ble.UniversalBle.availabilityStream;

  /// Connect / disconnect transitions for [deviceId] (`true` == connected).
  Stream<bool> connectionChanges(String deviceId) =>
      ble.UniversalBle.connectionStream(deviceId);

  /// Every GATT value update (notification, indication, or read-triggered),
  /// tagged with its normalized characteristic uuid. Consumers bucket by
  /// characteristic themselves — we deliberately don't pre-filter, so nothing is
  /// dropped by a deviceId/uuid mismatch (the WinRT trap described above).
  Stream<({String characteristicId, Uint8List value})> get characteristicUpdates =>
      _values.stream;

  /// Normalizes a uuid to the 128-bit lowercase form used to tag updates, so
  /// callers can match [characteristicUpdates] against discovered characteristic
  /// uuids.
  String normalizeUuid(String uuid) => ble.BleUuidParser.string(uuid);

  /// One-shot radio state, e.g. to decide whether a scan can start at all.
  Future<BleAvailability> availability() =>
      ble.UniversalBle.getBluetoothAvailabilityState();

  Future<bool> hasPermissions() => ble.UniversalBle.hasPermissions();
  Future<void> requestPermissions() => ble.UniversalBle.requestPermissions();

  /// Devices already connected to the OS (by any app). Lets us recover a device
  /// that stays connected after an app restart — it won't advertise, so a scan
  /// can't find it, but it shows up here.
  Future<List<BleDevice>> systemDevices() =>
      ble.UniversalBle.getSystemDevices();

  Future<void> startScan({BleScanFilter? filter}) =>
      ble.UniversalBle.startScan(scanFilter: filter);
  Future<void> stopScan() => ble.UniversalBle.stopScan();
  Future<bool> isScanning() => ble.UniversalBle.isScanning();

  /// Requests an ATT MTU for the connection and returns the negotiated value.
  /// Best-effort: the OS/peer may cap it below [mtu] (on Windows/Linux the MTU
  /// is auto-negotiated, so this effectively queries the current value).
  Future<int> requestMtu(String deviceId, int mtu) =>
      ble.UniversalBle.requestMtu(deviceId, mtu);

  Future<void> connect(String deviceId) => ble.UniversalBle.connect(deviceId);
  Future<void> disconnect(String deviceId) =>
      ble.UniversalBle.disconnect(deviceId);

  /// Enumerates GATT services/characteristics of a connected device.
  Future<List<BleGattService>> discoverServices(String deviceId) =>
      ble.UniversalBle.discoverServices(deviceId);

  /// Enables updates for a characteristic. Use [indicate] for characteristics
  /// that advertise indicate but not notify — the two use different CCCD bits,
  /// and requesting the wrong one leaves the characteristic silent.
  Future<void> subscribe(
    String deviceId,
    String service,
    String characteristic, {
    bool indicate = false,
  }) =>
      indicate
          ? ble.UniversalBle.subscribeIndications(deviceId, service, characteristic)
          : ble.UniversalBle.subscribeNotifications(
              deviceId, service, characteristic);
  Future<void> unsubscribe(
    String deviceId,
    String service,
    String characteristic,
  ) => ble.UniversalBle.unsubscribe(deviceId, service, characteristic);

  Future<Uint8List> read(String deviceId, String service, String characteristic) =>
      ble.UniversalBle.read(deviceId, service, characteristic);
  Future<void> write(
    String deviceId,
    String service,
    String characteristic,
    Uint8List value, {
    bool withoutResponse = false,
  }) => ble.UniversalBle.write(
    deviceId,
    service,
    characteristic,
    value,
    withoutResponse: withoutResponse,
  );

  /// Stops any in-flight scan and detaches our value handler on teardown.
  void dispose() {
    ble.UniversalBle.onValueChange = null;
    _values.close();
    ble.UniversalBle.stopScan();
  }
}

@Riverpod(keepAlive: true)
BleService bleService(Ref ref) {
  final service = BleService();
  ref.onDispose(service.dispose);
  return service;
}
