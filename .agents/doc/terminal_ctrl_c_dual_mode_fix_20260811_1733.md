# Terminal `Ctrl+C` Dual-Mode Handling Fix

## Overview

Fixed an issue where pressing `Ctrl+C` inside a terminal tab failed to copy text or interrupt running terminal commands.

## Root Cause

`Ctrl+C` was mapped to `CopySelectionTextIntent`. When no text was selected, `CopySelectionTextIntent` did nothing (`if (selection == null) return`), and blocked `Ctrl+C` from sending the ASCII `ETX` (`0x03` / `SIGINT`) signal to the shell or serial process.

## Solution

Updated `CopySelectionTextIntent` in [`actions.dart`](file:///D:/GIT/GitHub/xterm.dart/lib/src/ui/shortcut/actions.dart#L36):

- **When text IS selected**: Copies the highlighted text to the clipboard.
- **When NO text is selected**: Sends `terminal.keyInput(TerminalKey.keyC, ctrl: true)` (`0x03` interrupt signal) to cancel running shell commands or serial output streams.
- **`Ctrl+Shift+C`**: Always copies text to the clipboard.
