# Walkthrough: Fixed Terminal Tab Resize Crash

Fixed the `Null check operator used on a null value` error that occurred when resizing terminal panes / windows.

## Problem Summary

When terminal panes with scrollback history were resized, text reflow triggered `IndexAwareCircularBuffer.replaceWith()`. Due to `_startIndex` being reset to `0` **after** items were adopted rather than **before**, elements were positioned at the old non-zero offset while the buffer started reading from index 0. This left null gaps at index 0, causing `lines[0]!` in the renderer to fail with a null check error in both debug and release modes.

## Changes Made

### `xterm.dart`

#### [`circular_buffer.dart`](file:///D:/GIT/GitHub/xterm.dart/lib/src/utils/circular_buffer.dart#L233-L254)
- Set `_startIndex = 0;` before `_adoptChild` is called in `replaceWith`.
- Removed redundant `_dropChild` loop on `copyStart`.

#### [`circular_buffer_test.dart`](file:///D:/GIT/GitHub/xterm.dart/test/src/utils/circular_buffer_test.dart#L370-L410)
- Added tests verifying `replaceWith` behavior when `_startIndex > 0` (after circular wrap) and when `replacement.length > maxLength`.

## Verification

- Verified the circular buffer indexing logic and boundary conditions.
- Validated that `replaceWith` correctly attaches items starting at index 0 with no null entries.
