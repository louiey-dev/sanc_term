import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xterm/xterm.dart';

part 'terminal_instances.g.dart';

@Riverpod(keepAlive: true)
Terminal serialTerminal(Ref ref) => Terminal();

@Riverpod(keepAlive: true)
Terminal ptyTerminal(Ref ref) => Terminal();

@Riverpod(keepAlive: true)
TerminalController serialTerminalController(Ref ref) => TerminalController();

@Riverpod(keepAlive: true)
TerminalController ptyTerminalController(Ref ref) => TerminalController();
