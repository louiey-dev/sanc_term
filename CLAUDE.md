# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`sanc_term` is a multi-platform Flutter terminal application targeting serial communication protocols (UART, UDP, and others). It is in early development — `lib/main.dart` is still boilerplate.

**Design reference**: `sanc_term_design.md` (root of repo) is the primary design guide for architecture, layout, and supported terminal types. Check this file first when making structural decisions. It does not exist yet — create it before implementing core features.

**Reference codebase**: `D:\GIT\Flutter\flutter_terminal` — this is an earlier version of the app; refer to it for implementation patterns.

## Planned Architecture

- **State management**: Riverpod
- **Navigation**: go_router
- Globals should be compact and easy to read at a glance.

## Commands

```bash
flutter pub get        # Install/update dependencies
flutter analyze        # Run Dart static analysis (flutter_lints v5)
flutter test           # Run widget and unit tests
flutter run            # Run on connected device or desktop
flutter build windows  # Build for a specific platform (windows | linux | macos | apk | ios | web)
```

Run a single test file:

```bash
flutter test test/widget_test.dart
```

## Directory Structure

```
lib/          # All Dart source code (entry point: main.dart)
test/         # Widget and unit tests
android/
ios/
windows/
macos/
linux/
web/          # Platform-specific build layers — avoid editing unless targeting that platform
.agents/      # AI agent workspace rules (AGENTS.md)
```

`analysis_options.yaml` inherits from `package:flutter_lints/flutter.yaml`. Do not suppress lint rules without justification.

## Markdown

All `.md` files must pass markdownlint rules defined in `.markdownlint.json` (MD007, MD009, MD012, MD047 are explicitly enforced).
