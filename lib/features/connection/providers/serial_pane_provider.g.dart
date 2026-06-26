// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serial_pane_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$effectiveActiveSerialTabIdHash() =>
    r'6d031cc1f606de61a2d633044ecd837c1d3d2e06';

/// The SERIAL tab the connection bar currently acts on: the explicit selection
/// if it still exists, otherwise the first SERIAL pane. Null if none.
///
/// Copied from [effectiveActiveSerialTabId].
@ProviderFor(effectiveActiveSerialTabId)
final effectiveActiveSerialTabIdProvider =
    AutoDisposeProvider<String?>.internal(
      effectiveActiveSerialTabId,
      name: r'effectiveActiveSerialTabIdProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$effectiveActiveSerialTabIdHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EffectiveActiveSerialTabIdRef = AutoDisposeProviderRef<String?>;
String _$serialPaneNotifierHash() =>
    r'10c74f0d2e4639d1d9d5cb4d02717774ec84f1e9';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$SerialPaneNotifier
    extends BuildlessAutoDisposeNotifier<SerialPaneState> {
  late final String tabId;

  SerialPaneState build(String tabId);
}

/// Per-pane serial connection. Each SERIAL tab gets its own instance keyed by
/// tab id, so two panes can each hold an independent COM port.
///
/// Copied from [SerialPaneNotifier].
@ProviderFor(SerialPaneNotifier)
const serialPaneNotifierProvider = SerialPaneNotifierFamily();

/// Per-pane serial connection. Each SERIAL tab gets its own instance keyed by
/// tab id, so two panes can each hold an independent COM port.
///
/// Copied from [SerialPaneNotifier].
class SerialPaneNotifierFamily extends Family<SerialPaneState> {
  /// Per-pane serial connection. Each SERIAL tab gets its own instance keyed by
  /// tab id, so two panes can each hold an independent COM port.
  ///
  /// Copied from [SerialPaneNotifier].
  const SerialPaneNotifierFamily();

  /// Per-pane serial connection. Each SERIAL tab gets its own instance keyed by
  /// tab id, so two panes can each hold an independent COM port.
  ///
  /// Copied from [SerialPaneNotifier].
  SerialPaneNotifierProvider call(String tabId) {
    return SerialPaneNotifierProvider(tabId);
  }

  @override
  SerialPaneNotifierProvider getProviderOverride(
    covariant SerialPaneNotifierProvider provider,
  ) {
    return call(provider.tabId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'serialPaneNotifierProvider';
}

/// Per-pane serial connection. Each SERIAL tab gets its own instance keyed by
/// tab id, so two panes can each hold an independent COM port.
///
/// Copied from [SerialPaneNotifier].
class SerialPaneNotifierProvider
    extends
        AutoDisposeNotifierProviderImpl<SerialPaneNotifier, SerialPaneState> {
  /// Per-pane serial connection. Each SERIAL tab gets its own instance keyed by
  /// tab id, so two panes can each hold an independent COM port.
  ///
  /// Copied from [SerialPaneNotifier].
  SerialPaneNotifierProvider(String tabId)
    : this._internal(
        () => SerialPaneNotifier()..tabId = tabId,
        from: serialPaneNotifierProvider,
        name: r'serialPaneNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$serialPaneNotifierHash,
        dependencies: SerialPaneNotifierFamily._dependencies,
        allTransitiveDependencies:
            SerialPaneNotifierFamily._allTransitiveDependencies,
        tabId: tabId,
      );

  SerialPaneNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tabId,
  }) : super.internal();

  final String tabId;

  @override
  SerialPaneState runNotifierBuild(covariant SerialPaneNotifier notifier) {
    return notifier.build(tabId);
  }

  @override
  Override overrideWith(SerialPaneNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: SerialPaneNotifierProvider._internal(
        () => create()..tabId = tabId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tabId: tabId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<SerialPaneNotifier, SerialPaneState>
  createElement() {
    return _SerialPaneNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SerialPaneNotifierProvider && other.tabId == tabId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tabId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SerialPaneNotifierRef on AutoDisposeNotifierProviderRef<SerialPaneState> {
  /// The parameter `tabId` of this provider.
  String get tabId;
}

class _SerialPaneNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<SerialPaneNotifier, SerialPaneState>
    with SerialPaneNotifierRef {
  _SerialPaneNotifierProviderElement(super.provider);

  @override
  String get tabId => (origin as SerialPaneNotifierProvider).tabId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
