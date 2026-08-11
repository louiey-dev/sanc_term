# Terminal Select All (`Ctrl+A`) Full Buffer Selection Fix

## Overview

Updated `Ctrl+A` (`SelectAllTextIntent`) behavior so pressing `Ctrl+A` selects **all lines in the entire terminal scrollback buffer** rather than only the visible screen lines.

## Changes Made

1. **Full Buffer Anchor Selection**:
   - In [`actions.dart`](file:///D:/GIT/GitHub/xterm.dart/lib/src/ui/shortcut/actions.dart#L51), changed `SelectAllTextIntent` start anchor from `height - viewHeight` (top of visible screen) to `0` (top of entire scrollback history).
   - Selection now extends from `(0, 0)` to `(viewWidth, height - 1)`.

2. **Shortcut Mapping**:
   - In [`shortcuts.dart`](file:///D:/GIT/GitHub/xterm.dart/lib/src/ui/shortcut/shortcuts.dart#L18), ensured both `Ctrl+C` and `Ctrl+Shift+C` map to `CopySelectionTextIntent.copy`.

## Usage

- Press **`Ctrl+A`** inside the terminal: selects all lines across the entire 10,000-line scrollback buffer.
- Press **`Ctrl+C`** (or **`Ctrl+Shift+C`** / right-click copy): copies all selected lines to the clipboard.
