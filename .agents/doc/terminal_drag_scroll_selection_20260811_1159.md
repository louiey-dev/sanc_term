# Terminal Selection Auto-Scroll & Multi-Page Copy Fix

## Overview

Fixed an issue where selecting text across multiple pages during auto-scrolling only copied lines within the visible screen area (~41 lines).

## Root Cause

During drag selection, passing the initial screen-relative `Offset` on every drag update recalculated the selection start line based on the *new* scroll offset. As a result, the selection start anchor moved along with the viewport scrolling, truncating the selection range to only the lines currently visible on screen.

## Fix Details

1. **Buffer Anchor Locking**:
   - Locked `_dragStartCellOffset` to the absolute buffer coordinates (`CellOffset`) when drag starts.
   - Maintained an anchor at `_dragStartCellOffset` so that as the viewport scrolls up/down, the selection start position remains anchored at the original line in history while the selection end position moves to the new scrolled line.

2. **Full-Buffer Selection & Clipboard Copy**:
   - `controller.setSelection` now receives anchors that span across all scrolled lines (e.g. 500+ lines).
   - Copying to clipboard (`Ctrl+C` or context menu copy) extracts all lines within the full buffer range.

## Modified Files

- [`terminal_view.dart`](file:///D:/GIT/GitHub/xterm.dart/lib/src/terminal_view.dart#L165)
- [`gesture_detector.dart`](file:///D:/GIT/GitHub/xterm.dart/lib/src/ui/gesture/gesture_detector.dart#L20)
- [`gesture_handler.dart`](file:///D:/GIT/GitHub/xterm.dart/lib/src/ui/gesture/gesture_handler.dart#L185)
