# Terminal Paste Delay Control Feature

## Overview

Resolved issue where setting paste delay previously had no effect. Integrated paste delay properties (`pasteCharDelayMs` and `pasteLineDelayMs`) directly onto the `Terminal` core engine.

## Root Cause

An extension property was shadowing the core `Terminal` instance fields, causing `terminal.paste(text)` inside `xterm.dart` to read `0` ms default value instead of the active delay setting.

## Fix Details

1. **Native Field Integration**:
   - `Terminal.pasteCharDelayMs` and `Terminal.pasteLineDelayMs` are now native mutable properties on the `Terminal` class in [`terminal.dart`](file:///D:/GIT/GitHub/xterm.dart/lib/src/terminal.dart#L74).
   - `Terminal.paste(text)` directly consumes `pasteCharDelayMs` and `pasteLineDelayMs` for character & line delay streaming.

2. **Unified Execution**:
   - Right-click paste (`log_panel.dart`), keyboard shortcuts (`Ctrl+V` in `actions.dart`), and programmatic paste calls all invoke `terminal.paste(text)` which natively streams with character/line delays.

## Modified Files

- [`terminal.dart`](file:///D:/GIT/GitHub/xterm.dart/lib/src/terminal.dart#L74)
- [`terminal_tab.dart`](file:///D:/GIT/GitHub/sanc_term/lib/features/terminal/models/terminal_tab.dart#L7)
- [`log_panel.dart`](file:///D:/GIT/GitHub/sanc_term/lib/features/terminal/widgets/log_panel.dart#L526)
