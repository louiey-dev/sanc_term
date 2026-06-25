import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
    state = box.values
        .map((raw) => BoardProfile.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            ))
        .toList();
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
    final updated = box.values
        .map((raw) => BoardProfile.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            ))
        .map((p) => p.copyWith(isDefault: p.id == id))
        .toList();
    await box.clear();
    for (final p in updated) {
      await box.put(p.id, jsonEncode(p.toJson()));
    }
    await _load();
  }
}
