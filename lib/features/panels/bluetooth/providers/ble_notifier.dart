import 'dart:async';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanc_term/features/panels/bluetooth/ble_command.dart';
import 'package:sanc_term/features/panels/nordic/thingy53_parser.dart';
import 'package:sanc_term/services/ble_service.dart';

part 'ble_notifier.g.dart';

enum BleScanStatus { idle, scanning }

/// UI-facing snapshot of the BLE session: what the radio is doing, which
/// devices we have seen, the current connection, and — once connected — the
/// GATT tree plus per-characteristic subscriptions and received data.
///
/// Mechanism lives in [BleService]; this notifier only decides when to
/// scan/connect/subscribe and folds the service's streams into state the panels
/// can render. It is keepAlive so the connection survives navigating between the
/// Bluetooth LE and Thingy:53 panels (both watch this one provider).
class BleState {
  const BleState({
    this.scanStatus = BleScanStatus.idle,
    this.devices = const [],
    this.availability,
    this.selectedId,
    this.connectedId,
    this.connecting = false,
    this.services = const [],
    this.subscribed = const {},
    this.received = const {},
    this.maxPayload = const {},
    this.selectedChar,
    this.mtu,
    this.error,
    this.telemetry,
  });

  final BleScanStatus scanStatus;
  final List<BleDevice> devices;
  final BleAvailability? availability;

  /// Device the user has tapped in the list (the target for Connect).
  final String? selectedId;

  /// Device id of the live connection, or null when disconnected.
  final String? connectedId;
  final bool connecting;

  /// GATT services/characteristics discovered on the connected device.
  final List<BleGattService> services;

  /// Characteristic uuids we currently hold a notify/indicate subscription for.
  final Set<String> subscribed;

  /// Received payloads split per characteristic uuid, each in arrival order.
  /// Populated by notifications and one-shot reads; the panels render a chosen
  /// characteristic's buffer as text or hex.
  final Map<String, List<Uint8List>> received;

  /// Largest single notification payload (bytes) observed per characteristic —
  /// the ground-truth "how big did packets actually get" measurement. Survives
  /// buffer clears; reset on (re)connect.
  final Map<String, int> maxPayload;

  /// Characteristic uuid whose data is shown in the received-data view (and the
  /// default target for read/write in the compact controls).
  final String? selectedChar;

  /// Last negotiated ATT MTU for the connection (usable payload is MTU − 3),
  /// or null until requested/queried. Reset on (re)connect.
  final int? mtu;
  final String? error;
  final Thingy53Telemetry? telemetry;

  bool get isScanning => scanStatus == BleScanStatus.scanning;
  bool get isConnected => connectedId != null;

  /// Buffered chunks for [charUuid] (empty if none yet).
  List<Uint8List> receivedFor(String charUuid) =>
      received[charUuid] ?? const [];

  /// Byte total across [charUuid]'s buffered chunks.
  int byteCountFor(String charUuid) =>
      receivedFor(charUuid).fold(0, (sum, chunk) => sum + chunk.length);

  /// Largest single payload (bytes) seen on [charUuid] since connect (0 if none).
  int maxPayloadFor(String charUuid) => maxPayload[charUuid] ?? 0;

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
    List<BleGattService>? services,
    Set<String>? subscribed,
    Map<String, List<Uint8List>>? received,
    Map<String, int>? maxPayload,
    Object? selectedChar = _unset,
    Object? mtu = _unset,
    Object? error = _unset,
    Object? telemetry = _unset,
  }) {
    return BleState(
      scanStatus: scanStatus ?? this.scanStatus,
      devices: devices ?? this.devices,
      availability: identical(availability, _unset)
          ? this.availability
          : availability as BleAvailability?,
      selectedId: identical(selectedId, _unset)
          ? this.selectedId
          : selectedId as String?,
      connectedId: identical(connectedId, _unset)
          ? this.connectedId
          : connectedId as String?,
      connecting: connecting ?? this.connecting,
      services: services ?? this.services,
      subscribed: subscribed ?? this.subscribed,
      received: received ?? this.received,
      maxPayload: maxPayload ?? this.maxPayload,
      selectedChar: identical(selectedChar, _unset)
          ? this.selectedChar
          : selectedChar as String?,
      mtu: identical(mtu, _unset) ? this.mtu : mtu as int?,
      error: identical(error, _unset) ? this.error : error as String?,
      telemetry: identical(telemetry, _unset)
          ? this.telemetry
          : telemetry as Thingy53Telemetry?,
    );
  }
}

@Riverpod(keepAlive: true)
class BleNotifier extends _$BleNotifier {
  StreamSubscription<BleDevice>? _scanSub;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<BleAvailability>? _availSub;

  /// Single subscription to the service's global value stream; every incoming
  /// packet is bucketed into [BleState.received] by characteristic uuid, so
  /// nothing is lost to a per-characteristic filter mismatch.
  StreamSubscription<({String characteristicId, Uint8List value})>? _valuesSub;

  /// Characteristics the user asked to subscribe (charUuid → serviceUuid),
  /// remembered across drops so [reconnect] can re-enable them after a device
  /// power-cycle. Cleared only on an explicit [disconnect].
  final Map<String, String> _desiredSubs = {};

  /// Cap on buffered chunks per characteristic so a chatty peripheral can't grow
  /// state unbounded.
  static const _maxChunks = 1000;

  late final BleService _ble;

  @override
  BleState build() {
    _ble = ref.read(bleServiceProvider);
    ref.onDispose(_cleanup);
    // Track radio availability, and seed it once with the current value.
    _availSub = _ble.availabilityChanges.listen(
      (a) => state = state.copyWith(availability: a),
    );
    // Route every GATT value update into the per-characteristic buffers. The
    // service's stream is broadcast and always live, so this stays attached for
    // the notifier's lifetime.
    _valuesSub = _ble.characteristicUpdates.listen((e) {
      if (e.characteristicId == NusUuids.tx) {
        final bytes = e.value;
        if (bytes.length >= 2 && bytes[0] == 0xA5 && bytes[1] == 0x5A) {
          // byte array message
          Thingy53Parser.parseByteArray(bytes);
        } else {
          // string data or json
          final parsed = Thingy53Parser.parse(e.value);
          state = state.copyWith(telemetry: parsed);
        }
      }
      _onRx(e.characteristicId, e.value);
    });
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
  void select(String deviceId) => state = state.copyWith(selectedId: deviceId);

  Future<void> toggleScan() => state.isScanning ? stopScan() : startScan();

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

  /// Loads devices already connected to the OS into the device list, so a device
  /// that stayed connected across an app restart (and thus won't appear in a
  /// scan) can be selected and connected/reconnected. Auto-selects the sole
  /// result when nothing is selected yet.
  Future<void> loadSystemDevices() async {
    try {
      final system = await _ble.systemDevices();
      final byId = {for (final d in state.devices) d.deviceId: d};
      for (final d in system) {
        byId[d.deviceId] = d;
      }
      state = state.copyWith(devices: byId.values.toList(), error: null);
      if (state.selectedId == null && system.length == 1) {
        state = state.copyWith(selectedId: system.first.deviceId);
      }
    } catch (e) {
      state = state.copyWith(error: 'System devices: $e');
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
    // Fresh GATT/receive state for the new session.
    state = state.copyWith(
      connecting: true,
      services: const [],
      subscribed: const {},
      received: const {},
      maxPayload: const {},
      selectedChar: null,
      mtu: null,
      error: null,
      telemetry: null,
    );
    // Watch the connection so an unexpected drop clears our state too.
    _connSub?.cancel();
    _connSub = _ble.connectionChanges(id).listen((connected) {
      if (!connected) {
        state = state.copyWith(
          connectedId: null,
          connecting: false,
          services: const [],
          subscribed: const {},
          telemetry: null,
        );
      } else {
        state = state.copyWith(connectedId: id, connecting: false);
      }
    });
    try {
      await _ble.connect(id);
      state = state.copyWith(connectedId: id, connecting: false);
      await _discover(id);
    } catch (e) {
      await _connSub?.cancel();
      _connSub = null;
      state = state.copyWith(connecting: false, error: '$e');
    }
  }

  /// Enumerates the GATT tree so the panels can offer per-characteristic
  /// subscribe/read/write. Nothing is subscribed automatically — the user picks.
  Future<void> _discover(String id) async {
    try {
      final services = await _ble.discoverServices(id);
      state = state.copyWith(services: services);
    } catch (e) {
      state = state.copyWith(error: 'Discover failed: $e');
    }
  }

  /// Re-runs GATT discovery on the connected device.
  Future<void> rediscover() async {
    final id = state.connectedId;
    if (id != null) await _discover(id);
  }

  /// Forces a clean re-sync with the current device: drops the link, reconnects,
  /// re-discovers the GATT tree, and re-enables the previously subscribed
  /// characteristics. Use this after power-cycling the board — on Windows the OS
  /// keeps a rebooted device "connected" and silently auto-reconnects, so our
  /// GATT handles and CCCD subscriptions go stale with no event to tell us.
  Future<void> reconnect() async {
    final id = state.connectedId ?? state.selectedId;
    if (id == null || state.connecting) return;
    // Capture intent before disconnect() clears it.
    final desired = Map<String, String>.from(_desiredSubs);
    if (state.connectedId != null) await disconnect();
    await connect(id);
    if (state.connectedId != id) return; // reconnect failed; error already set
    for (final entry in desired.entries) {
      await subscribeChar(entry.value, entry.key);
    }
  }

  /// Requests a larger ATT MTU to raise the per-packet payload (payload =
  /// MTU − 3) and returns the negotiated value (null on failure/not connected).
  /// The OS/peer may cap it below the request; on Windows the MTU is fixed at
  /// connection time, so this reports the already-negotiated value.
  Future<int?> requestMtu(int mtu) async {
    final id = state.connectedId;
    if (id == null) return null;
    try {
      final negotiated = await _ble.requestMtu(id, mtu);
      state = state.copyWith(mtu: negotiated);
      return negotiated;
    } catch (e) {
      state = state.copyWith(error: 'MTU request failed: $e');
      return null;
    }
  }

  /// Sets the characteristic whose buffer the received-data view shows.
  void selectChar(String charUuid) =>
      state = state.copyWith(selectedChar: charUuid);

  /// Turns on notifications/indications for [charUuid] and streams its payloads
  /// into [BleState.received]. Also makes it the viewed characteristic. Starts
  /// listening before enabling the CCCD so the first packets aren't missed.
  Future<void> subscribeChar(String serviceUuid, String charUuid) async {
    final id = state.connectedId;
    if (id == null || state.subscribed.contains(charUuid)) return;
    // Prefer notify; fall back to indicate for indicate-only characteristics.
    final ch = _findChar(serviceUuid, charUuid);
    final indicate =
        ch != null &&
        !ch.properties.contains(BleCharProperty.notify) &&
        ch.properties.contains(BleCharProperty.indicate);
    try {
      await _ble.subscribe(id, serviceUuid, charUuid, indicate: indicate);
      _desiredSubs[charUuid] = serviceUuid;
      state = state.copyWith(
        subscribed: {...state.subscribed, charUuid},
        selectedChar: charUuid,
      );
    } catch (e) {
      state = state.copyWith(error: 'Subscribe failed: $e');
    }
  }

  /// Turns off notifications for [charUuid] (its buffered data is kept).
  Future<void> unsubscribeChar(String serviceUuid, String charUuid) async {
    final id = state.connectedId;
    _desiredSubs.remove(charUuid);
    if (id != null) {
      try {
        await _ble.unsubscribe(id, serviceUuid, charUuid);
      } catch (e) {
        state = state.copyWith(error: 'Unsubscribe failed: $e');
      }
    }
    state = state.copyWith(subscribed: {...state.subscribed}..remove(charUuid));
  }

  /// One-shot read of [charUuid]; the value lands in its buffer like a
  /// notification would, and it becomes the viewed characteristic.
  Future<void> readChar(String serviceUuid, String charUuid) async {
    final id = state.connectedId;
    if (id == null) return;
    try {
      final value = await _ble.read(id, serviceUuid, charUuid);
      _onRx(charUuid, value);
      state = state.copyWith(selectedChar: charUuid);
    } catch (e) {
      state = state.copyWith(error: 'Read failed: $e');
    }
  }

  /// Writes [value] to [charUuid], picking with/without response from the
  /// characteristic's advertised properties.
  Future<void> writeChar(
    String serviceUuid,
    String charUuid,
    Uint8List value, {
    bool? withoutResponse,
  }) async {
    final id = state.connectedId;
    if (id == null) return;
    final ch = _findChar(serviceUuid, charUuid);
    final useWithoutResponse = withoutResponse ??
        (ch != null &&
            !ch.properties.contains(BleCharProperty.write) &&
            ch.properties.contains(BleCharProperty.writeWithoutResponse));
    try {
      await _ble.write(
        id,
        serviceUuid,
        charUuid,
        value,
        withoutResponse: useWithoutResponse,
      );
    } catch (e) {
      state = state.copyWith(error: 'Write failed: $e');
    }
  }

  BleCharacteristic? _findChar(String serviceUuid, String charUuid) {
    for (final s in state.services) {
      if (s.uuid != serviceUuid) continue;
      for (final ch in s.characteristics) {
        if (ch.uuid == charUuid) return ch;
      }
    }
    return null;
  }

  void _onRx(String charUuid, Uint8List data) {
    final next = {...state.received};
    final chunks = [...(next[charUuid] ?? const <Uint8List>[]), data];
    if (chunks.length > _maxChunks) {
      chunks.removeRange(0, chunks.length - _maxChunks);
    }
    next[charUuid] = chunks;
    // Record a new high-water mark for this characteristic's payload size.
    Map<String, int>? maxes;
    if (data.length > (state.maxPayload[charUuid] ?? 0)) {
      maxes = {...state.maxPayload, charUuid: data.length};
    }
    state = state.copyWith(received: next, maxPayload: maxes);
  }

  /// Clears one characteristic's buffer, or all buffers when [charUuid] is null.
  void clearReceived([String? charUuid]) {
    if (charUuid == null) {
      state = state.copyWith(received: const {});
      return;
    }
    state = state.copyWith(received: {...state.received}..remove(charUuid));
  }

  Future<void> disconnect() async {
    final id = state.connectedId;
    if (id == null) return;
    _desiredSubs.clear();
    try {
      await _ble.disconnect(id);
    } catch (e) {
      state = state.copyWith(error: '$e');
    }
    await _connSub?.cancel();
    _connSub = null;
    state = state.copyWith(
      connectedId: null,
      connecting: false,
      services: const [],
      subscribed: const {},
      telemetry: null,
    );
  }

  void _cleanup() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _availSub?.cancel();
    _valuesSub?.cancel();
    _ble.stopScan();
  }
}
