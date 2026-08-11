# Terminal Scrollback Buffer Capacity Update

## Overview

Updated the default terminal scrollback buffer line limit in `sanc_term` from 1,000 lines to 10,000 lines per tab.

## Modified Files

- [`lib/features/terminal/models/terminal_tab.dart`](file:///D:/GIT/GitHub/sanc_term/lib/features/terminal/models/terminal_tab.dart#L8)

## Key Changes

1. **Increased Default `maxLines`**:
   - `TerminalTab` constructor now accepts an optional `maxLines` parameter (defaults to `10000`).
   - `Terminal(maxLines: maxLines)` passes this configuration directly to `xterm.dart`.

2. **Custom Capacity**:
   - Individual terminal tabs (Serial, PTY, BLE) can now be created with custom line buffer limits if needed.
