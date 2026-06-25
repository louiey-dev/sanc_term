# TODO List for sanc_term

`sanc_term_design.md` is the primary design reference.
Details and features will evolve during implementation, but the design doc is the baseline.

---

## Priority 1 — Riverpod (eliminate globals)

- [ ] Add Riverpod packages to `pubspec.yaml`
  (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `riverpod_lint`)
- [ ] Create `lib/services/serial_service.dart` with `@Riverpod(keepAlive: true)` provider
- [ ] Create `lib/services/udp_service.dart` with `@Riverpod(keepAlive: true)` provider
- [ ] Create `lib/services/pty_service.dart` with `@Riverpod(keepAlive: true)` provider
- [ ] Create `lib/features/connection/providers/connection_provider.dart`
  (`ConnectionNotifier` with `connect` / `disconnect`)
- [ ] Create `lib/features/terminal/providers/terminal_provider.dart`
  (`TerminalNotifier`)

## Priority 2 — go_router + Panel Registry (eliminate switch)

- [ ] Add `go_router` to `pubspec.yaml`
- [ ] Create `lib/core/router/` with routes:
  - `/` → connection screen (when disconnected)
  - `/home` → main shell
  - `/home/panel/:panelId` → deep-linkable panels
- [ ] Create `lib/features/panels/panel_registry.dart`
  (map of `panelId → Widget factory`, replaces the `switch` in `_buildActivePanel()`)
- [ ] Stub panel widgets for each target type:
  - `nvidia/`: `NvGpioPanel`, `NvHdmiPanel`
  - `rockchip/`: `RcGpioPanel`
  - `diagnostics/`: `DnCpuPanel`
  - `esp/`: (TBD — define panel list based on ESP feature set)
- [ ] Wire sidebar to call `context.go('/home/panel/:panelId')` from registry

## Priority 3 — Freezed Models (eliminate raw strings)

- [ ] Add `freezed`, `freezed_annotation`, `json_serializable`, `build_runner`
  to `pubspec.yaml`
- [ ] Create `lib/shared/models/serial_config.dart` (`SerialConfig` — port, baud,
  encoding, newline)
- [ ] Create `lib/shared/models/log_entry.dart` (`LogEntry`)
- [ ] Create `lib/shared/models/board_command.dart` (`BoardCommand`)
- [ ] Run `dart run build_runner build` to generate `.freezed.dart` and `.g.dart` files

## Setup & Structure

- [ ] Set up feature-first folder structure under `lib/`
  (see `sanc_term_design.md` — Folder Structure section)
- [ ] Add remaining packages to `pubspec.yaml`:
  `flutter_libserialport`, `flutter_pty`, `xterm`, `window_manager`,
  `shared_preferences`, `multi_split_view`, `logger`, `package_info_plus`
- [ ] Create `lib/core/theme/` (`AppColors`, `AppTheme`)
- [ ] Create `lib/core/utils/` (formatters, ANSI stripper)

## UI

- [ ] Design connection bar (status pill: `COM3 | 115200 | UTF-8 | Connected ●`)
- [ ] Add tab support to log panel (serial + UDP side by side using `xterm`)
- [ ] Drive sidebar groups from `panel_registry` (data-driven, not hardcoded)
- [ ] Board profile system (save/restore port, baud, IP, target type on launch)
- [ ] Switch log panel splitter to `multi_split_view` (drag-to-resize with saved state)

## Questions for AI

- Can you access `D:\GIT\Flutter\flutter_terminal`?
  → Yes — Claude Code can read any local path. Reference it freely for
  implementation patterns; it is the predecessor to this app.
