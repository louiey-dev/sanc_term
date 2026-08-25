# Terminal Paste Delay Hangup Fix

## Overview

Resolved UI freeze / hangup when changing terminal paste delay settings.

## Root Cause

`TerminalTabsNotifier.build()` was watching `pasteSettingsNotifierProvider` (`ref.watch`). Whenever paste delay settings were updated, Riverpod triggered a full rebuild of `TerminalTabsNotifier`, destroying active terminal tab instances and creating a cyclic rebuild cascade while `_applyToActiveTerminals()` was executing.

## Fix Details

1. **Rebuild Decoupling**:
   - In [`terminal_instances.dart`](file:///D:/GIT/GitHub/sanc_term/lib/features/terminal/providers/terminal_instances.dart#L28), changed `ref.watch(pasteSettingsNotifierProvider)` to `ref.read(pasteSettingsNotifierProvider)`.

2. **Direct In-Memory Property Application**:
   - `PasteSettingsNotifier._applyToActiveTerminals()` now directly updates properties on existing active terminal instances without triggering a tab notifier state rebuild or destroying open PTY / Serial sessions.
