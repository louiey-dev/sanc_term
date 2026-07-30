import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terminal_credentials_provider.g.dart';

/// Credentials model for terminal connections.
class TerminalCredentials {
  final String ip;
  final String id;
  final String password;

  const TerminalCredentials({
    this.ip = '',
    this.id = '',
    this.password = '',
  });

  TerminalCredentials copyWith({
    String? ip,
    String? id,
    String? password,
  }) {
    return TerminalCredentials(
      ip: ip ?? this.ip,
      id: id ?? this.id,
      password: password ?? this.password,
    );
  }
}

@riverpod
Future<Box<String>> terminalCredentialsBox(Ref ref) async {
  try {
    return await Hive.openBox<String>('terminal_credentials');
  } catch (_) {
    if (Hive.isBoxOpen('terminal_credentials')) {
      return Hive.box<String>('terminal_credentials');
    }
    return await Hive.openBox<String>('terminal_credentials', bytes: Uint8List(0));
  }
}

@riverpod
class TerminalCredentialsNotifier extends _$TerminalCredentialsNotifier {
  @override
  TerminalCredentials build() {
    _init();
    return const TerminalCredentials();
  }

  Future<void> _init() async {
    final box = await ref.read(terminalCredentialsBoxProvider.future);
    state = TerminalCredentials(
      ip: box.get('ip', defaultValue: '') ?? '',
      id: box.get('id', defaultValue: '') ?? '',
      password: box.get('password', defaultValue: '') ?? '',
    );
  }

  Future<void> updateIp(String value) async {
    state = state.copyWith(ip: value);
    final box = await ref.read(terminalCredentialsBoxProvider.future);
    await box.put('ip', value);
  }

  Future<void> updateId(String value) async {
    state = state.copyWith(id: value);
    final box = await ref.read(terminalCredentialsBoxProvider.future);
    await box.put('id', value);
  }

  Future<void> updatePassword(String value) async {
    state = state.copyWith(password: value);
    final box = await ref.read(terminalCredentialsBoxProvider.future);
    await box.put('password', value);
  }
}
