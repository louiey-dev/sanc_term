---
name: sanc-term
description: >-
  Comprehensive development guide and architectural reference for the sanc_term
  multi-platform Flutter terminal application. Covers directory structure, Riverpod state
  management, GoRouter panel navigation, per-pane serial and PTY terminal management,
  board command execution, BLE/UDP/Telemetry services, and step-by-step procedures for adding
  new panels and features. Use whenever developing, extending, or debugging sanc_term.
---

# sanc_term Development Skill & Architectural Reference

`sanc_term` is a modular, high-performance multi-platform Flutter terminal application tailored for embedded development and hardware diagnostics (NVIDIA Jetson, Rockchip, STM32, Nordic nRF, Espressif ESP, LTE modules).

---

## 1. Project Overview & Architecture

### Core Architecture Principles

1. **Feature-First Organization**: Every user-facing domain lives in `lib/features/<name>/` with its own `providers/`, `widgets/`, and optional `models/`.
2. **Decoupled Panel System**: Adding a panel never modifies `home_screen.dart` or uses large `switch` statements. Screens are dynamically routed via `GoRouter` using `panel_registry.dart`.
3. **No Top-Level Globals**: All shared and hardware state is managed via typed Riverpod providers (`@riverpod` and `@Riverpod(keepAlive: true)`).
4. **Strict Layer Decoupling**:
   - `services/` $\rightarrow$ Raw I/O only (no Flutter widget imports).
   - `features/` $\rightarrow$ Business logic + feature UI (uses `services/` & `shared/`).
   - `shared/` $\rightarrow$ Generic reusable UI components and cross-feature Freezed models (no imports from `features/`).
   - `core/` $\rightarrow$ Infrastructure (router, theme extension, utils).

---

## 2. Directory Structure

```text
lib/
├── core/                         # Infrastructure & global utilities
│   ├── router/                   # GoRouter configuration (app_router.dart)
│   ├── theme/                    # AppColors (ThemeExtension), sanc_term_theme.dart, terminal_theme.dart
│   └── utils/                    # my_utils.dart (logger, snackbars), formatters.dart
│
├── services/                     # Raw I/O (@Riverpod(keepAlive: true) - NO Flutter widgets)
│   ├── serial_service.dart       # flutter_libserialport wrapper
│   ├── pty_service.dart          # flutter_pty process spawner
│   ├── ble_service.dart          # universal_ble Bluetooth LE manager
│   ├── udp_service.dart          # UDP socket sender/listener
│   ├── file_logger_service.dart  # Multi-pane terminal log file writer
│   └── telemetry_server_service.dart # HTTP JSON streaming server on localhost:18765
│
├── features/                     # Feature modules
│   ├── connection/               # Hardware connection management
│   │   ├── models/               # Feature-specific connection models
│   │   ├── providers/            # serial_pane_provider, board_console, board_profile_service
│   │   └── widgets/              # connection_bar.dart, board_profile_picker.dart, cmd_history_dropdown.dart
│   │
│   ├── terminal/                 # Multi-pane xterm terminal
│   │   ├── models/               # terminal_tab.dart (serial / pty tab descriptor)
│   │   ├── providers/            # terminal_instances.dart (TerminalTabsNotifier), credentials, paste settings
│   │   └── widgets/              # log_panel.dart (MultiSplitView terminal tabs & consoles)
│   │
│   ├── home/                     # Top-level shell layout
│   │   ├── home_screen.dart      # ShellRoute frame (ConnectionBar + vertical MultiSplitView)
│   │   └── widgets/              # menu_sidebar.dart (collapsible panel menu)
│   │
│   ├── settings/                 # App settings
│   │
│   └── panels/                   # Device & tool panel implementations
│       ├── panel_registry.dart   # Central panelGroups list & _realPanels routing map
│       ├── common/               # cm_cmd_history, cm_general_settings, cm_time_setting, cm_udp, cm_webrtc, stub_panel
│       ├── diagnostics/          # dn_cpu, dn_memory, dn_power, dn_storage, dn_peripheral, dn_display, dn_wifi_ble, dn_gpio, dn_rtc_sensor
│       ├── nvidia/               # nv_settings, nv_gpio, nv_hdmi, nv_ethernet, nv_uart, nv_leds, nv_nvme, nv_usb, nv_audio
│       ├── rockchip/             # rc_settings, rc_gpio, rc_uart, rc_i2c, rc_sensors, rc_display, rc_mpp, rc_network, rc_storage, rc_usb
│       ├── esp/                  # esp_at, esp_ota
│       ├── nordic/               # nrf_uart, nrf_ble, nrf_ota, thingy53
│       ├── stm32/                # f746_disco, f746_disco_wifi, f746_disco_ble
│       ├── bluetooth/            # bluetooth_le
│       ├── lte/                  # lte_module
│       ├── voice/                # odv_default (On-Device Voice)
│       └── customs/              # fire_cam, rv1106, tof, uvc_stream
│
└── shared/                       # Cross-feature reusable building blocks
    ├── models/                   # Freezed data models (serial_config, board_profile, log_entry, board_command)
    └── widgets/                  # panel.dart (MyPanel, MyPanelBody, PanelActionButton), common.dart
```

---

## 3. Key Subsystems & Implementation Details

### 3.1. Layout & Shell Architecture

`HomeScreen` (`lib/features/home/home_screen.dart`) is wrapped by a `ShellRoute` in `app_router.dart`:

```text
Scaffold
└── Column
    ├── ConnectionBar                         # Top full-width bar (serial config, baud, port scan, profile)
    └── MultiSplitView (Vertical drag divider)
        ├── Area "main" (Flex 3) ── Row
        │   ├── MenuSidebar                   # Left sidebar (220px, collapsible groups, search)
        │   └── Expanded( widget.child )      # Middle-right routed panel (/home/panel/:panelId)
        └── Area "log"  (Flex 1)              # Bottom multi-pane terminal (log_panel.dart)
```

### 3.2. Panel Registry & Dynamic Routing

Panels are registered in `lib/features/panels/panel_registry.dart`:

1. **`panelGroups`**: Defines groups (`COMMON`, `ROCKCHIP`, `NVIDIA`, `DIAGNOSTICS`, `ESPRESSIF`, `NORDIC nRF`, `LTE MODULE`, `ON-DEVICE VOICE`, `Bluetooth LE`, `STM32`, `CUSTOMS`) and `PanelEntry` items displayed in `MenuSidebar`.
2. **`panelRegistry`**: Maps IDs to builders. Defaults every entry to `StubPanel(entry: entry)`.
3. **`_realPanels`**: Maps implemented panel IDs to real `ConsumerWidget` instances.

**Routing Flow**:
`MenuSidebar` $\rightarrow$ `context.go('/home/panel/<id>')` $\rightarrow$ `app_router.dart` $\rightarrow$ `panelRegistry[id]` $\rightarrow$ Rendered widget.

### 3.3. Per-Pane Terminal & Serial Transport

- **`TerminalTabsNotifier`** (`lib/features/terminal/providers/terminal_instances.dart`): Owns the collection of open terminal tabs (`TerminalTab`), each containing an `xterm.Terminal`, `TerminalController`, `FocusNode`, and type (`serial` / `pty`).
- **`SerialPaneNotifier`** (`lib/features/connection/providers/serial_pane_provider.dart`): A `.family` notifier keyed by `tabId`. Each serial tab manages its own isolated COM port and I/O streams.
- **Active Pane & Hotkeys**: `Alt+1..9` hotkeys switch between terminal panes and set active focus.

### 3.4. Board Console & Command Execution

`lib/features/connection/providers/board_console.dart` defines the `BoardConsole` abstraction:

1. **Fire-and-Forget Command** (`sendBoardCommand` in `lib/features/panels/common/board_command.dart`):
   Sends raw string + terminator to the active board console. Output streams to the terminal pane.

   ```dart
   sendBoardCommand(ref, context, 'cat /proc/cpuinfo');
   ```

2. **Command Output Capture** (`ConsoleCommandSession.run()`):
   Executes a shell command and captures pure stdout using a quote-split end marker (`echo SANC"END"<nonce>`):
   - Prevents local echo from matching the marker.
   - Cleans ANSI escape sequences.
   - Automatically handles non-newline outputs.

3. **Console Priority Selection** (`pickBoardConsole(ref)`):
   1. Active/focused SERIAL tab (if connected).
   2. Any connected SERIAL tab.
   3. Any connected PTY/SSH pane.
   4. `null` (shows error snackbar).

### 3.5. Theme & Styling Conventions

- All colors derive from `AppColors` (`ThemeExtension`) in `lib/core/theme/sanc_term_theme.dart`.
- Access in widgets via `context.colors` (e.g., `c.primary`, `c.surface`, `c.muted`, `c.text`, `c.cardBg`).
- Never hardcode arbitrary `Color(0x...)` values in panel UI.
- Terminal theme is synchronized in `lib/core/theme/terminal_theme.dart`.

---

## 4. Step-by-Step Development Runbooks

### Runbook A: How to Add a New Panel

#### Step 1: Create the Panel Widget

Create `lib/features/panels/<category>/<panel_name>.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/features/panels/common/board_command.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

class MyNewFeaturePanel extends ConsumerWidget {
  const MyNewFeaturePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PanelActionButton btn(IconData icon, String label, String cmd) =>
        PanelActionButton(
          icon: icon,
          label: label,
          tooltipStr: cmd,
          onPressed: () => sendBoardCommand(ref, context, cmd),
        );

    return MyPanel(
      icon: Icons.developer_board,
      panelTitle: 'My Feature',
      panelSubtitle: 'Feature description and controls',
      panelActions: const [],
      children: [
        MyPanelBody(
          icon: Icons.tune,
          title: 'Controls',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              btn(Icons.play_arrow, 'Start Status', 'systemctl status my_service'),
              btn(Icons.info_outline, 'Get Info', 'cat /etc/my_config.conf'),
            ],
          ),
        ),
      ],
    );
  }
}
```

#### Step 2: Register in `panel_registry.dart`

Open `lib/features/panels/panel_registry.dart`:

1. Add `PanelEntry` to the appropriate `PanelGroup` in `panelGroups`:

   ```dart
   PanelEntry(
     id: 'my_new_feature',
     label: 'My Feature',
     description: 'Feature description and controls',
     icon: Icons.developer_board,
   ),
   ```

2. Register the builder in `_realPanels`:

   ```dart
   'my_new_feature': () => const MyNewFeaturePanel(),
   ```

---

### Runbook B: How to Add a Freezed Model or Riverpod Notifier

1. Define model in `lib/shared/models/<model_name>.dart` or feature folder:

   ```dart
   import 'package:freezed_annotation/freezed_annotation.dart';

   part 'my_model.freezed.dart';
   part 'my_model.g.dart';

   @freezed
   class MyModel with _$MyModel {
     const factory MyModel({
       required String id,
       @Default(0) int count,
     }) = _MyModel;

     factory MyModel.fromJson(Map<String, dynamic> json) => _$MyModelFromJson(json);
   }
   ```

2. Run code generation:

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

---

## 5. Essential CLI Commands

```bash
# Install dependencies
flutter pub get

# Static code analysis (flutter_lints + riverpod_lint)
flutter analyze

# Execute test suite
flutter test

# Run code generator (freezed, riverpod, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for continuous code generation
dart run build_runner watch --delete-conflicting-outputs

# Run on desktop / device
flutter run -d windows

# Build release desktop binary
flutter build windows
```

> [!IMPORTANT]
> The `xterm` package is linked locally via path `../xterm.dart` in `pubspec.yaml` due to customized patch requirements. Ensure the sibling directory exists when resolving packages.

---

## 6. Critical Conventions & Verification Rules

1. **No Layer Leakage**: Never import `features/` files inside `services/` or `shared/`.
2. **No Switch-Case Panel Dispatch**: Always resolve panels through `GoRouter` and `panel_registry.dart`.
3. **Markdown Compliance**: All `.md` documents must satisfy `.markdownlint.json` (MD007 2-space indent, MD009 no trailing spaces, MD012 no double blank lines, MD047 trailing newline).
4. **Log Storage Strategy**: `FileLoggerService` writes to `%USERPROFILE%\Desktop` on Windows and standard app documents on other platforms.
