# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project

`sanc_term` is a multi-platform Flutter terminal app for talking to embedded boards
(NVIDIA Jetson, Rockchip, ESP, LTE modules) over serial/UART and PTY consoles. It is a
rewrite of an earlier app (`D:\GIT\Flutter\flutter_terminal`) with a feature-first,
Riverpod-based architecture; refer to that codebase for older implementation patterns.

**Design references**: `sanc_term_design.md` explains the architecture rationale and the
"what goes where" decision guide. `README.md` documents the screen layout tree and the
sidebar → router → panel registry flow. Read both before structural changes.

## Commands

```bash
flutter pub get          # Install/update dependencies
dart format <changed-dart-files>   # Format every modified Dart source file
flutter analyze          # Static analysis (flutter_lints v5)
flutter test             # Run all tests
flutter test test/tegra_stats_test.dart   # Run a single test file
flutter run              # Run on connected device / desktop
flutter build windows    # Build a platform (windows | linux | macos | apk | ios | web)

# Code generation — REQUIRED after editing any @riverpod / @freezed / json file.
# Generated *.g.dart and *.freezed.dart are committed; regenerate them, don't hand-edit.
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs   # keep running while developing
```

Note: `xterm` is a local path dependency (`../xterm.dart`, a patched fork) — it must exist
as a sibling directory for `flutter pub get` to succeed.

## Toolchain and dependencies

- Follow the Dart SDK constraint in `pubspec.yaml` (currently `^3.9.2`).
- Keep the patched `../xterm.dart` path dependency. Do not replace it with the pub.dev
  package without explicit approval.
- Do not upgrade dependencies or regenerate `pubspec.lock` unless the requested change
  requires it.
- Never hand-edit `*.g.dart` or `*.freezed.dart`. Regenerate and commit them with their
  source changes.

## Architecture

Feature-first layout under `lib/`. The layering rule is strict and is what keeps panels
decoupled:

- **`services/`** — raw I/O only, no Flutter widgets. `@Riverpod(keepAlive: true)`
  providers that each own one resource: `serial_service`, `udp_service`, `pty_service`,
  `file_logger_service`. Rule of thumb: would it exist in a non-Flutter Dart CLI? Then it
  belongs here.
- **`features/<name>/providers/`** — Riverpod notifiers that turn user actions into state
  using `services/`. Service = mechanism (opens the port); provider = decision (when to open,
  whether it's open).
- **`features/<name>/widgets/`** — UI meaningful only inside that feature.
- **`shared/`** — `widgets/` (generic UI: `MyPanel`, `PanelBody`, `MyPanelBody`,
  `PanelHeader`, toolbar buttons) and `models/` (Freezed models used by >1 feature:
  `SerialConfig`, `BoardProfile`, `LogEntry`, `BoardCommand`). No imports from `features/`.
- **`core/`** — app skeleton: `router/` (go_router), `theme/`, `utils/`
  (`app_logger`, `formatters`, `snackbars`).

### Screen layout

`HomeScreen` (`features/home/home_screen.dart`) is a `ShellRoute` wrapper: a full-width
`ConnectionBar` on top, then a vertical `MultiSplitView` splitting the `MenuSidebar` + routed
panel content (`main`, flex 3) from the `LogPanel` terminal panes (`log`, flex 1).

### Panels & the registry (how to add a screen)

Panels are routed, never switched on. Flow:
`MenuSidebar` → `context.go('/home/panel/<id>')` → `app_router.dart` →
`panel_registry.dart` → widget.

To add a panel:

1. Add a `PanelEntry` to the appropriate `PanelGroup` in `panel_registry.dart` (`panelGroups`
   drives both the sidebar and the default registry).
2. Every id automatically maps to a `StubPanel` until you add a real builder to the
   `_realPanels` map in the same file. That's the only wiring needed — `home_screen.dart` is
   never touched.

Panel widgets are `ConsumerWidget`s built from `shared/widgets` (`MyPanel` containing
`MyPanelBody` sections). Unknown ids fall through to `NotFoundPanel`.

### Terminal panes & per-pane serial connections

`TerminalTabsNotifier` (`features/terminal/providers/terminal_instances.dart`,
keepAlive) owns the list of `TerminalTab`s — each holds its own xterm `Terminal`,
`TerminalController`, and `FocusNode`, typed `serial` or `pty`.

Serial connections are **per-pane**: `SerialPaneNotifier` is a `.family` keyed by `tabId`,
so each SERIAL tab holds an independent COM port. The `ConnectionBar` acts on
`effectiveActiveSerialTabId` (explicit selection via tap / Alt+N, else the first serial pane).
`Alt+1..9` (handled in `home_screen.dart`) moves focus to the Nth pane and makes serial panes
active.

### Running commands on a board & capturing output

`board_console.dart` defines `BoardConsole` (implemented by `PtyConsole` and the serial
adapter). `ConsoleCommandSession.run()` captures a command's stdout by appending a
quote-split end marker (`echo SANC"END"<nonce>`): the shell prints `SANCEND<nonce>` while the
echoed line keeps the quotes, so a substring search matches only real output. `send()` is
fire-and-forget (output just flows to the terminal). Panels find a live console via
`boardConsoleRegistryProvider`.

### Theme

Colors come from `AppColors`, a `ThemeExtension` with `dark`/`light` variants. Access them in
widgets via `context.colors` (extension in `sanc_term_theme.dart`) — e.g. `c.primary`,
`c.surface`, `c.muted`. `themeModeProvider` drives light/dark. Don't hardcode `Color(...)`
in panels; pull from `context.colors`.

## Resource lifecycle

- The service or notifier that creates a serial port, PTY, BLE subscription, UDP socket,
  stream subscription, timer, controller, or focus node owns its cleanup.
- Preserve per-pane isolation; never introduce a shared serial connection for terminal panes.
- Keep parsing and I/O loops non-blocking, responsive, and bounded. Do not perform blocking
  hardware or process I/O on the UI isolate.
- Handle disconnects, disposal, and late stream events without updating disposed notifiers
  or widgets.

## Testing and verification

- Run `dart format` on every modified Dart file.
- Run the smallest relevant test first, then `flutter test` when practical. Run
  `flutter analyze` after Dart changes.
- Prefer deterministic unit tests for parsers, command-output extraction, formatters, and
  provider decisions. Mock or abstract hardware I/O; ordinary tests must not require a
  connected serial, BLE, UDP, or PTY device.
- Add a regression test for a bug fix when the affected behavior can be tested
  deterministically.
- Do not report hardware-dependent behavior as verified unless it was tested with the
  relevant device and transport.
- In the final response, list the checks actually run and distinguish passed, failed, and
  skipped checks. Never claim an unrun check passed.

## Persistence and sensitive data

- Treat Hive keys and serialized model fields as compatibility contracts. Supply defaults
  or migration handling when changing persisted schemas.
- Never log or commit passwords, credentials, tokens, private keys, or captured user data.

## Platform files

- Avoid changing generated Flutter scaffolding under `android/`, `ios/`, `linux/`, `macos/`,
  `web/`, or `windows/` unless the task requires platform-specific integration.
- When adding a plugin, verify its support and required configuration for every affected
  platform.

## Conventions

- Globals/providers should be compact and readable at a glance (see `sanc_term_design.md`).
- `analysis_options.yaml` currently inherits `package:flutter_lints/flutter.yaml`.
  `riverpod_lint` is a development dependency but is not currently configured as an active
  analyzer plugin. Don't suppress lint rules without justification.
- All `.md` files must pass `.markdownlint.json` (MD007, MD009, MD012, MD047 enforced).
- Hive is initialized in `main.dart` (Windows: `%APPDATA%\sanc_term`; else app documents
  dir). Log files default to the Desktop on Windows, the documents dir elsewhere.
- `.agents/AGENTS.md` holds the workspace persona/rules for AI agents.

## Instruction scope

- This root file contains repository-wide rules. `.agents/AGENTS.md` adds workspace persona
  and generated-document conventions.
- Apply both files. If instructions conflict, follow the more specifically scoped file and
  call out any ambiguity that materially affects the task.
- Save agent-generated working Markdown documents under `.agents/doc/` using
  `<purpose>_yyyymmdd_hhmm.md`, as required by `.agents/AGENTS.md`. Do not move normal project
  documentation there.
