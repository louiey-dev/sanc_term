import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanc_term/services/ble_service.dart';

part 'ble_notifier.g.dart';

enum BleScanStatus { idle, scanning }

/// UI-facing snapshot of the BLE session: what the radio is doing, which
/// devices we have seen, and the current connection. Mechanism lives in
/// [BleService]; this notifier only decides when to scan/connect and folds the
/// service's streams into state the panel can render.
class BleState {
  const BleState({
    this.scanStatus = BleScanStatus.idle,
    this.devices = const [],
    this.availability,
    this.selectedId,
    this.connectedId,
    this.connecting = false,
    this.error,
  });

  final BleScanStatus scanStatus;
  final List<BleDevice> devices;
  final BleAvailability? availability;

  /// Device the user has tapped in the list (the target for Connect).
  final String? selectedId;

  /// Device id of the live connection, or null when disconnected.
  final String? connectedId;
  final bool connecting;
  final String? error;

  bool get isScanning => scanStatus == BleScanStatus.scanning;
  bool get isConnected => connectedId != null;

  // Sentinel so nullable fields are preserved when omitted; pass an explicit
  // `null` to clear one.
  static const _unset = Object();

  BleState copyWith({
    BleScanStatus? scanStatus,
    List<BleDevice>? devices,
    Object? availability = _unset,
    Object? selectedId = _unset,
    Object? connectedId = _unset,
    bool? connecting,
    Object? error = _unset,
  }) {
    return BleState(
      scanStatus: scanStatus ?? this.scanStatus,
      devices: devices ?? this.devices,
      availability: identical(availability, _unset)
          ? this.availability
          : availability as BleAvailability?,
      selectedId:
          identical(selectedId, _unset) ? this.selectedId : selectedId as String?,
      connectedId: identical(connectedId, _unset)
          ? this.connectedId
          : connectedId as String?,
      connecting: connecting ?? this.connecting,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

@riverpod
class BleNotifier extends _$BleNotifier {
  StreamSubscription<BleDevice>? _scanSub;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<BleAvailability>? _availSub;

  BleService get _ble => ref.read(bleServiceProvider);

  @override
  BleState build() {
    ref.onDispose(_cleanup);
    // Track radio availability, and seed it once with the current value.
    _availSub = _ble.availabilityChanges.listen(
      (a) => state = state.copyWith(availability: a),
    );
    _seedAvailability();
    return const BleState();
  }

  // Best-effort one-shot read of the current radio state. Kept in its own async
  // method (not `.then(onError:)`, whose error handler must return the future's
  // type) so a rejected probe can't throw an unhandled error.
  Future<void> _seedAvailability() async {
    try {
      final a = await _ble.availability();
      state = state.copyWith(availability: a);
    } catch (_) {
      // Leave availability unknown; scanning surfaces its own errors.
    }
  }

  /// Selects a discovered device as the Connect target.
  void select(String deviceId) =>
      state = state.copyWith(selectedId: deviceId);

  Future<void> toggleScan() =>
      state.isScanning ? stopScan() : startScan();

  Future<void> startScan() async {
    if (state.isScanning) return;
    state = state.copyWith(
      scanStatus: BleScanStatus.scanning,
      devices: const [],
      error: null,
    );
    _scanSub?.cancel();
    _scanSub = _ble.scanResults.listen(_onDevice);
    try {
      // Best-effort: startScan() already requests permissions where the platform
      // needs them, and the explicit call is a no-op on desktop — so a failure
      // here (e.g. an unimplemented channel) must not block the actual scan.
      try {
        await _ble.requestPermissions();
      } catch (_) {}
      await _ble.startScan();
    } catch (e) {
      await _scanSub?.cancel();
      _scanSub = null;
      state = state.copyWith(scanStatus: BleScanStatus.idle, error: '$e');
    }
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    try {
      await _ble.stopScan();
    } catch (_) {}
    state = state.copyWith(scanStatus: BleScanStatus.idle);
  }

  /// Empties the discovered-device list (and any pending selection). Leaves an
  /// active scan and the current connection untouched.
  void clearDevices() =>
      state = state.copyWith(devices: const [], selectedId: null);

  // Advertisements repeat, so replace an existing entry (fresher rssi/name)
  // rather than appending duplicates.
  void _onDevice(BleDevice device) {
    final devices = [...state.devices];
    final i = devices.indexWhere((d) => d.deviceId == device.deviceId);
    if (i >= 0) {
      devices[i] = device;
    } else {
      devices.add(device);
    }
    state = state.copyWith(devices: devices);
  }

  Future<void> connect([String? deviceId]) async {
    final id = deviceId ?? state.selectedId;
    if (id == null || state.connecting || state.connectedId == id) return;
    if (state.isScanning) await stopScan();
    state = state.copyWith(connecting: true, error: null);
    // Watch the connection so an unexpected drop clears our state too.
    _connSub?.cancel();
    _connSub = _ble.connectionChanges(id).listen((connected) {
      state = state.copyWith(
        connectedId: connected ? id : null,
        connecting: false,
      );
    });
    try {
      await _ble.connect(id);
      state = state.copyWith(connectedId: id, connecting: false);
    } catch (e) {
      await _connSub?.cancel();
      _connSub = null;
      state = state.copyWith(connecting: false, error: '$e');
    }
  }

  Future<void> disconnect() async {
    final id = state.connectedId;
    if (id == null) return;
    try {
      await _ble.disconnect(id);
    } catch (e) {
      state = state.copyWith(error: '$e');
    }
    await _connSub?.cancel();
    _connSub = null;
    state = state.copyWith(connectedId: null, connecting: false);
  }

  void _cleanup() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _availSub?.cancel();
    _ble.stopScan();
  }
}
