# TODO List for sanc_term

`sanc_term_design.md` is the primary design reference.
Details and features will evolve during implementation, but the design doc is the baseline.

---

## Priority 1 — Riverpod (eliminate globals)

- [x] Add Riverpod packages to `pubspec.yaml`
  (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `riverpod_lint`)
- [x] Create `lib/services/serial_service.dart` with `@Riverpod(keepAlive: true)` provider
- [x] Create `lib/services/udp_service.dart` with `@Riverpod(keepAlive: true)` provider
- [x] Create `lib/services/pty_service.dart` with `@Riverpod(keepAlive: true)` provider
- [x] Create `lib/features/connection/providers/connection_provider.dart`
  (`ConnectionNotifier` with `connect` / `disconnect`)
- [x] Create `lib/features/terminal/providers/terminal_provider.dart`
  (`TerminalNotifier`)

## Priority 2 — go_router + Panel Registry (eliminate switch)

- [x] Add `go_router` to `pubspec.yaml`
- [x] Create `lib/core/router/` with routes:
  - `/` → connection screen (when disconnected)
  - `/home` → main shell
  - `/home/panel/:panelId` → deep-linkable panels
- [x] Create `lib/features/panels/panel_registry.dart`
  (map of `panelId → Widget factory`, replaces the `switch` in `_buildActivePanel()`)
- [x] Stub panel widgets for each target type (all via `StubPanel` — replace per panel as implemented):
  - `nvidia/`: nv_settings, nv_gpio, nv_hdmi, nv_ethernet, nv_uart, nv_leds, nv_nvme, nv_audio
  - `rockchip/`: rc_settings, rc_gpio, rc_uart, rc_i2c, rc_sensors, rc_display, rc_mpp, rc_network, rc_storage, rc_usb
  - `diagnostics/`: dn_power, dn_cpu, dn_memory, dn_storage, dn_peripheral, dn_display, dn_wifi_ble, dn_gpio, dn_rtc_sensor
  - `esp/`: esp_at, esp_ota
  - `common/`: cm_cmd_history, cm_general_settings, cm_time_setting
  - `lte/`: lte_module
- [x] Wire sidebar to call `context.go('/home/panel/:panelId')` from registry

## Priority 3 — Freezed Models (eliminate raw strings)

- [x] Add `freezed`, `freezed_annotation`, `json_annotation`, `json_serializable`
  to `pubspec.yaml` (use `freezed: ^3.x` — v2.x conflicts with `riverpod_lint` via `analyzer_plugin`)
- [x] Create `lib/shared/models/serial_config.dart` (`SerialConfig` — port, baud,
  encoding, newline; includes `SerialEncoding` and `NewLine` enums with label/suffix extensions)
- [x] Create `lib/shared/models/log_entry.dart` (`LogEntry` — text, timestamp, source, level)
- [x] Create `lib/shared/models/board_command.dart` (`BoardCommand` — id, command, label, description)
- [x] Run `dart run build_runner build` to generate `.freezed.dart` and `.g.dart` files

## Setup & Structure

- xterm : its package has a bug which is not fixed so need to use `../xterm.dart`
- [x] Set up feature-first folder structure under `lib/`
- [x] Add remaining packages to `pubspec.yaml`:
  `flutter_libserialport`, `flutter_pty`, `xterm`, `window_manager`,
  `hive_ce`, `multi_split_view`, `logger`, `package_info_plus`
- [x] Create `lib/core/theme/` (`AppColors`, `AppTheme`)
- [x] Create `lib/core/utils/` (`app_logger`, `formatters`, `snackbars`)
- [x] Add dark/light theme mode selection menu
  — `themeModeProvider` in `lib/core/theme/theme_provider.dart`
  — `AppColors` is now a `ThemeExtension` with `dark`/`light`; access via `context.colors`
  — Toggle `IconButton` (sun/moon) added to `ConnectionBar`
- [x] Add log file save button
  — `FileLoggerNotifier` in `lib/services/file_logger_service.dart`
  — Save/stop `IconButton` in `LogPanel` header (floppy → red stop when active)
  — PTY data fed through logger; serial will hook in when wired
- [x] Add timestamp option button while file logging
  — Clock `IconButton` in `LogPanel` header; teal when on, muted when off
  — `FileLoggerState.timestampEnabled` toggles per-line `[DateTime]` prefix

## UI

- [x] Design connection bar (status pill: `COM3 | 115200 | UTF-8 | Connected ●`)
  — `lib/features/connection/widgets/connection_bar.dart`
  — Port scan, port/baud/encoding/newline dropdowns, connect/disconnect, status pill
- [x] Split-view log panel (all terminals visible at once, drag-to-resize)
  — `lib/features/terminal/widgets/log_panel.dart`
  — `MultiSplitView(axis: horizontal)` — one pane per terminal, not tabs
  — `TerminalTabsNotifier` owns the list; `+` menu adds Serial/PTY, `×` closes a pane
  — Each pane has its own xterm TerminalView, label, clear, right-click copy/paste
  — PTY auto-starts shell (`cmd.exe /k chcp 65001` on Windows); killed on pane close
  — xterm moved from dev_dependencies to dependencies
- [x] Drive sidebar groups from `panel_registry` (data-driven, not hardcoded)
  — done in Priority 2; `panelGroups` const drives both sidebar and registry
- [x] Board profile system (save/restore port, baud, IP, target type on launch)
  — `lib/shared/models/board_profile.dart` (Freezed + JSON)
  — `lib/features/connection/providers/board_profile_service.dart` (SharedPreferences)
  — `lib/features/connection/widgets/board_profile_picker.dart` (popup in connection bar)
  — Note: isar_community_generator conflicts with riverpod_generator (build version);
    using hive_ce + Freezed JSON instead (Box<String>, profile.id as key)
- [x] Switch log panel splitter to `multi_split_view` (drag-to-resize with saved state)
  — `home_screen.dart` uses `MultiSplitView(axis: Axis.vertical)` 75/25 split
  — Divider styled with `AppColors.border` / `AppColors.primary` on hover

## Questions for AI

- Can you access `D:\GIT\Flutter\flutter_terminal`?
  → Yes — Claude Code can read any local path. Reference it freely for
  implementation patterns; it is the predecessor to this app.
