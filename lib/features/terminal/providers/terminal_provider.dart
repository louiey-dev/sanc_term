import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terminal_provider.g.dart';

class TerminalState {
  const TerminalState({this.lines = const []});
  final List<String> lines;
}

@riverpod
class TerminalNotifier extends _$TerminalNotifier {
  @override
  TerminalState build() => const TerminalState();

  void appendLine(String line) {
    state = TerminalState(lines: [...state.lines, line]);
  }

  void clear() {
    state = const TerminalState();
  }
}
