# sanc_term

terminal app which supports xtem/uart/udp support

## Layout tree

Scaffold ─ Column
├─ ConnectionBar                         ← top bar, full width
└─ MultiSplitView (vertical, draggable divider)
   ├─ area "main"  (flex 3)  ── Row
   │   ├─ MenuSidebar                     ← LEFT column (fixed 220px)
   │   └─ Expanded( widget.child )        ← MIDDLE-RIGHT (routed content)
   └─ area "log"   (flex 1)               ← BOTTOM window (terminal panes)

Block → file
┌───────────────────────┬─────────────────────────────────────────────────────┬────────────────────────────────┐
│     Screen block      │                        File                         │             Notes              │
├───────────────────────┼─────────────────────────────────────────────────────┼────────────────────────────────┤
│ Top bar (serial       │ lib/features/connection/widgets/connection_bar.dart │ Full-width, above everything   │
│ options)              │                                                     │                                │
├───────────────────────┼─────────────────────────────────────────────────────┼────────────────────────────────┤
│ Left column (menu)    │ lib/features/home/widgets/menu_sidebar.dart         │ 220px fixed; collapsible       │
│                       │                                                     │ groups                         │
├───────────────────────┼─────────────────────────────────────────────────────┼────────────────────────────────┤
│ Middle-right (main    │ routed — widget.child                               │ not one file — see below       │
│ content)              │                                                     │                                │
├───────────────────────┼─────────────────────────────────────────────────────┼────────────────────────────────┤
│ Bottom window         │ lib/features/terminal/widgets/log_panel.dart        │ The split terminal panes       │
│ (terminals)           │                                                     │ you've been editing            │
├───────────────────────┼─────────────────────────────────────────────────────┼────────────────────────────────┤
│ The whole frame       │ lib/features/home/home_screen.dart                  │ Owns the Column + vertical     │
│                       │                                                     │ split                          │
└───────────────────────┴─────────────────────────────────────────────────────┴────────────────────────────────┘

The middle-right is routed, not a single file

That widget.child is filled by go_router, so its content changes with what you click in the left sidebar:

  1. lib/core/router/app_router.dart — the ShellRoute wraps everything in HomeScreen and decides what child is:
     - /home → a centered "Select a panel" placeholder
     - /home/panel/:panelId → looks the id up in the panel registry
  2. lib/features/panels/panel_registry.dart — maps each panel id to the actual widget shown in the middle-right. This is where you add/find the screens themselves.
  3. lib/features/panels/models/panel_entry.dart + the panelGroups list — defines the sidebar menu items (label, icon, description) that link to those panels.

So the flow is:
  sidebar item (menu_sidebar.dart) → context.go(`/home/panel/<id>`) → router (app_router.dart) → panel_registry.dart → widget rendered in the middle-right.

## Screens

![sanc_term_dark](sanc_term_dark.png)  ![sanc_term_light](sanc_term_light.png)

## Features

- 🚀 Cross platform: mobile, desktop, browser
- 📚 Terminal support: xterm, uart, udp support
- 🗄️ Log support: save terminal log to file
  - in Windows, save to Desktop by default
  - other OS, save to DOC directory
- 🔥 popular packages
  - riverpod for state management, go_router for routing
  - hive/window manager support
  - hive for data storage, window manager for window
  - xterm for terminal support
    - xterm package is inside of local due to bug patch
- 🪟 multiple window support
  - serial, pty support
  - short key support, move between windows via `ALT + 1/2/3/4...`
  - log file is logging all of open windows (only one log file available)
- 🌗 dark/light theme support

## History

- 2026.06.25
  - Preparing based on flutter_terminal app for more better architect and performance
  - implemented basic features at `sanc_term_design.md`
  - multiple uart/pty window open support
  - log file dir is desktop by default
- 2026.06.26
  - short key added at terminal to move between windows (`ALT + 1/2/3...`)
  - modify settings menu to handle more menu options
    - add about pop up window
  - added most of panels with default menu items but not tested&verified
  - test&verified 'Tegra Stats' menu and plot
- 2026.06.29
  - uart message send to unselected port issue fixed
    - uart message send to selected uart window
- 2026.06.30
  - History button added at connection_bar for efficient history navigation
  - save current panel and restore previously activated panel at start up
  - added my_utils.dart which includes logger/snackbar and other utilities
  - add ssh button
- 2026.07.01
  - scan com port list took long time and fixed it
- 2026.07.02
  - miner code fixed
  - add localhost switch which sends parsed data to <http://localhost:18765>
    - sanc_graph gets streamed data and display plot
- 2026.07.06
  - add nVidia Ethernet performance test menu
  - add nvidia USB panel
- 2026.07.08
  - add bluetooth panel
  - add udp panel
- 2026.07.10
  - add NORDIC panel
    - thingy53

## Info

- Flutter/Dart
- Author : <louiey.dev@gmail.com>
- Version : 0.1.0
