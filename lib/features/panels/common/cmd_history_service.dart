import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cmd_history_service.g.dart';

const _favKey = 'favorites';
const _recentKey = 'recents';
const _maxRecents = 12;

/// Seeded into favorites the first time the panel is opened. Once the user
/// edits favorites (even down to empty) the stored list takes over.
const defaultFavorites = <String>[
  'uname -a',
  'uptime -p',
  'df -h',
  'free -h',
  'dmesg | tail -n 40',
  'ps aux | head -n 20',
];

/// Persisted command history: pinned favorites and a rolling recent list.
class CmdHistoryState {
  final List<String> favorites;
  final List<String> recents;

  const CmdHistoryState({this.favorites = const [], this.recents = const []});

  CmdHistoryState copyWith({List<String>? favorites, List<String>? recents}) =>
      CmdHistoryState(
        favorites: favorites ?? this.favorites,
        recents: recents ?? this.recents,
      );
}

@Riverpod(keepAlive: true)
Future<Box<String>> cmdHistoryBox(Ref ref) async {
  return Hive.openBox<String>('cmd_history');
}

@Riverpod(keepAlive: true)
class CmdHistoryNotifier extends _$CmdHistoryNotifier {
  Box<String>? _box;

  @override
  CmdHistoryState build() {
    _load();
    return const CmdHistoryState();
  }

  Future<Box<String>> _ensureBox() async {
    final existing = _box;
    if (existing != null) return existing;
    final box = await ref.read(cmdHistoryBoxProvider.future);
    _box = box;
    return box;
  }

  List<String> _readList(Box<String> box, String key, List<String> fallback) {
    final raw = box.get(key);
    if (raw == null) return List.of(fallback);
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> _load() async {
    final box = await _ensureBox();
    state = CmdHistoryState(
      favorites: _readList(box, _favKey, defaultFavorites),
      recents: _readList(box, _recentKey, const []),
    );
  }

  Future<void> _persist() async {
    final box = await _ensureBox();
    await box.put(_favKey, jsonEncode(state.favorites));
    await box.put(_recentKey, jsonEncode(state.recents));
  }

  /// Records [cmd] as the most recent, de-duplicating and capping the list.
  void addRecent(String cmd) {
    final t = cmd.trim();
    if (t.isEmpty) return;
    final recents = [t, ...state.recents.where((c) => c != t)];
    if (recents.length > _maxRecents) {
      recents.removeRange(_maxRecents, recents.length);
    }
    state = state.copyWith(recents: recents);
    _persist();
  }

  void pin(String cmd) {
    final t = cmd.trim();
    if (t.isEmpty || state.favorites.contains(t)) return;
    state = state.copyWith(favorites: [...state.favorites, t]);
    _persist();
  }

  void unpin(String cmd) {
    state = state.copyWith(
      favorites: state.favorites.where((c) => c != cmd).toList(),
    );
    _persist();
  }

  void clearRecents() {
    state = state.copyWith(recents: const []);
    _persist();
  }
}
