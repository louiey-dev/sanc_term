import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_ble/universal_ble.dart' as ble;

part 'ble_service.g.dart';

// Re-export the package model types the provider/UI layers need so they can
// stay on this façade and not import universal_ble directly.
typedef BleDevice = ble.BleDevice;
typedef BleGattService = ble.BleService;
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
  /// Devices discovered during the active scan. Emits one event per
  /// advertisement, so the same device can appear repeatedly (dedupe upstream).
  Stream<BleDevice> get scanResults => ble.UniversalBle.scanStream;

  /// Radio power / permission transitions (poweredOn, poweredOff, unauthorized…).
  Stream<BleAvailability> get availabilityChanges =>
      ble.UniversalBle.availabilityStream;

  /// Connect / disconnect transitions for [deviceId] (`true` == connected).
  Stream<bool> connectionChanges(String deviceId) =>
      ble.UniversalBle.connectionStream(deviceId);

  /// Notifications / indications from a subscribed characteristic.
  Stream<Uint8List> characteristicValues(String deviceId, String characteristic) =>
      ble.UniversalBle.characteristicValueStream(deviceId, characteristic);

  /// One-shot radio state, e.g. to decide whether a scan can start at all.
  Future<BleAvailability> availability() =>
      ble.UniversalBle.getBluetoothAvailabilityState();

  Future<bool> hasPermissions() => ble.UniversalBle.hasPermissions();
  Future<void> requestPermissions() => ble.UniversalBle.requestPermissions();

  Future<void> startScan({BleScanFilter? filter}) =>
      ble.UniversalBle.startScan(scanFilter: filter);
  Future<void> stopScan() => ble.UniversalBle.stopScan();
  Future<bool> isScanning() => ble.UniversalBle.isScanning();

  Future<void> connect(String deviceId) => ble.UniversalBle.connect(deviceId);
  Future<void> disconnect(String deviceId) =>
      ble.UniversalBle.disconnect(deviceId);

  /// Enumerates GATT services/characteristics of a connected device.
  Future<List<BleGattService>> discoverServices(String deviceId) =>
      ble.UniversalBle.discoverServices(deviceId);

  Future<void> subscribe(String deviceId, String service, String characteristic) =>
      ble.UniversalBle.subscribeNotifications(deviceId, service, characteristic);
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

  /// Stops any in-flight scan on teardown. Streams are owned by the platform
  /// singleton, so there is nothing else to close here.
  void dispose() {
    ble.UniversalBle.stopScan();
  }
}

@Riverpod(keepAlive: true)
BleService bleService(Ref ref) {
  final service = BleService();
  ref.onDispose(service.dispose);
  return service;
}
