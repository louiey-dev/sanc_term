// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_profile_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$boardProfileBoxHash() => r'730c431f711eb000a2165f4ede737b1a9c633d91';

/// See also [boardProfileBox].
@ProviderFor(boardProfileBox)
final boardProfileBoxProvider = FutureProvider<Box<String>>.internal(
  boardProfileBox,
  name: r'boardProfileBoxProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$boardProfileBoxHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BoardProfileBoxRef = FutureProviderRef<Box<String>>;
String _$boardProfilesNotifierHash() =>
    r'117898245205a5460319b8656fbcf69a250f6a07';

/// See also [BoardProfilesNotifier].
@ProviderFor(BoardProfilesNotifier)
final boardProfilesNotifierProvider =
    NotifierProvider<BoardProfilesNotifier, List<BoardProfile>>.internal(
      BoardProfilesNotifier.new,
      name: r'boardProfilesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$boardProfilesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BoardProfilesNotifier = Notifier<List<BoardProfile>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
