import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanc_term/core/utils/my_utils.dart';
import 'package:sanc_term/shared/models/board_profile.dart';

part 'board_profile_service.g.dart';

@Riverpod(keepAlive: true)
Future<Box<String>> boardProfileBox(Ref ref) async {
  return Hive.openBox<String>('board_profiles');
}

@Riverpod(keepAlive: true)
class BoardProfilesNotifier extends _$BoardProfilesNotifier {
  @override
  List<BoardProfile> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final box = await ref.read(boardProfileBoxProvider.future);
    state = box.values.map(_tryDecode).whereType<BoardProfile>().toList();
  }

  /// Decodes one stored profile, tolerating an empty or corrupt entry (e.g. a
  /// zero-byte write left behind by a crash mid-save) by skipping it instead of
  /// failing the whole load.
  BoardProfile? _tryDecode(String raw) {
    if (raw.isEmpty) return null;
    try {
      return BoardProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      gUtils.err('Skipping corrupt board profile: $e');
      return null;
    }
  }

  Future<void> save(BoardProfile profile) async {
    final box = await ref.read(boardProfileBoxProvider.future);
    await box.put(profile.id, jsonEncode(profile.toJson()));
    await _load();
  }

  Future<void> delete(String id) async {
    final box = await ref.read(boardProfileBoxProvider.future);
    await box.delete(id);
    await _load();
  }

  Future<void> setDefault(String id) async {
    final box = await ref.read(boardProfileBoxProvider.future);
    // Rewrite only the entries whose default flag actually changes, so a crash
    // mid-update can never wipe the box (unlike a clear-then-rewrite).
    for (final raw in box.values.toList()) {
      final p = _tryDecode(raw);
      if (p == null) continue;
      final shouldBeDefault = p.id == id;
      if (p.isDefault != shouldBeDefault) {
        await box.put(
          p.id,
          jsonEncode(p.copyWith(isDefault: shouldBeDefault).toJson()),
        );
      }
    }
    await _load();
  }
}
