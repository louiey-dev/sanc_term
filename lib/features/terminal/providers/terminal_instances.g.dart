// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_instances.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$terminalTabsNotifierHash() =>
    r'76b810921dc7880d3694f6a5dab20cc38dc88d84';

/// See also [TerminalTabsNotifier].
@ProviderFor(TerminalTabsNotifier)
final terminalTabsNotifierProvider =
    NotifierProvider<TerminalTabsNotifier, List<TerminalTab>>.internal(
      TerminalTabsNotifier.new,
      name: r'terminalTabsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$terminalTabsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TerminalTabsNotifier = Notifier<List<TerminalTab>>;
String _$activeTabIdHash() => r'271272cac1a854778e75ea564e869f7e016b3b60';

/// See also [ActiveTabId].
@ProviderFor(ActiveTabId)
final activeTabIdProvider = NotifierProvider<ActiveTabId, String?>.internal(
  ActiveTabId.new,
  name: r'activeTabIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeTabIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveTabId = Notifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
