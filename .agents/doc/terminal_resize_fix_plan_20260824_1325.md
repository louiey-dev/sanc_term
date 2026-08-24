# Implementation Plan: Fix Terminal Tab Resize Null Check Exception

## Goal Description

When resizing terminal tabs in `sanc_term` (or resizing split panes/windows), a rendering exception is thrown:
`Null check operator used on a null value` originating from `TerminalView` / `RenderTerminal`.

This document details why the issue occurs, whether it affects release (`.exe`) builds, and how to fix it in `xterm.dart`.

---

## Technical Root Cause Analysis

### 1. Does this happen only in debug mode?

**No.**
In Dart with sound null safety, the `!` operator (null assertion) throws a runtime exception (`NullCheckError` / `TypeError: Null check operator used on a null value`) in **both Debug and Release (.exe) modes**.
In release mode, when this exception is thrown during Flutter's render phase (`RenderTerminal.paint` / `performLayout`), Flutter catches it in the rendering pipeline, corrupting the terminal's visual state or freezing updates for that pane.

### 2. Why does this happen?

The terminal buffer uses `IndexAwareCircularBuffer<BufferLine>` to store scrollback history and active lines.

When the terminal accumulates scrollback lines beyond its initial capacity:
1. `push` advances `_startIndex` (e.g., `_startIndex = 45`). The items are stored cyclically across indices `[45..max]` and `[0..44]`.
2. When the user resizes a terminal tab or the window:
   - `RenderTerminal.performLayout` runs and determines a change in column/row dimensions.
   - `RenderTerminal` calls `_terminal.resize()`, which in turn calls `_mainBuffer.resize()`.
   - `_mainBuffer.resize()` reflows the terminal text lines and calls `lines.replaceWith(reflowResult)`.
3. In `IndexAwareCircularBuffer.replaceWith` (`xterm.dart/lib/src/utils/circular_buffer.dart`):

```dart
// BUGGY IMPLEMENTATION in circular_buffer.dart:
void replaceWith(List<T> replacement) {
  for (var i = 0; i < _length; i++) {
    _dropChild(i);
  }

  var copyStart = 0;
  if (replacement.length > maxLength) {
    copyStart = replacement.length - maxLength;
  }

  for (var i = 0; i < copyStart; i++) {
    _dropChild(i);
  }

  final copyLength = replacement.length - copyStart;
  for (var i = 0; i < copyLength; i++) {
    _adoptChild(i, replacement[copyStart + i]); // Uses OLD _startIndex (e.g. 45)!
  }

  _startIndex = 0; // BUG: Resets _startIndex to 0 AFTER adopting items!
  _length = copyLength;
}
```

4. Because `_adoptChild(i, ...)` uses `_getCyclicIndex(i)` which computes `(_startIndex + i) % length`, elements were placed starting at array index `45` (i.e. `_array[45..]`).
5. Then `_startIndex = 0;` was executed.
6. When Flutter subsequently renders `RenderTerminal.paint()` and accesses `lines[0]` via `operator [](0)`:
   - `_getChild(0)` reads `_array[(0 + 0) % length]` = `_array[0]`, which is `null`!
   - `return _getChild(index)!` fails on `null!`, throwing `Null check operator used on a null value`.

---

## Proposed Changes

### `xterm.dart`

#### [MODIFY] `lib/src/utils/circular_buffer.dart`

- Reset `_startIndex = 0` **before** calling `_adoptChild` in `replaceWith`.
- Remove the redundant `_dropChild` loop on `copyStart`.

```dart
  /// Replaces all elements in the list with [replacement].
  void replaceWith(List<T> replacement) {
    for (var i = 0; i < _length; i++) {
      _dropChild(i);
    }

    _startIndex = 0;

    var copyStart = 0;
    if (replacement.length > maxLength) {
      copyStart = replacement.length - maxLength;
    }

    final copyLength = replacement.length - copyStart;
    for (var i = 0; i < copyLength; i++) {
      _adoptChild(i, replacement[copyStart + i]);
    }

    _length = copyLength;
  }
```

#### [MODIFY] `test/src/utils/circular_buffer_test.dart`

- Add a unit test specifically verifying `replaceWith` on a circular buffer where `_startIndex > 0` (after circular overflow wrap).

---

## Verification Plan

### Automated Tests
- Run `flutter test test/src/utils/circular_buffer_test.dart` in `D:/GIT/GitHub/xterm.dart` to verify that `replaceWith` with `_startIndex > 0` succeeds without producing null elements.
- Run `flutter test test/src/core/buffer/buffer_test.dart` in `D:/GIT/GitHub/xterm.dart` to verify buffer resizing and reflowing.

### Manual Verification
1. Run `sanc_term`.
2. Generate logs/output in the terminal so scrollback exceeds the view height.
3. Drag the split divider to resize the terminal pane horizontally and vertically.
4. Verify that no `Null check operator used on a null value` error occurs and rendering stays responsive.
