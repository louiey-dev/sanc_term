# sanc_term — Architecture & Design Guide

This app is updated version of flutter_terminal.
It's designed to be more modular with more features.

## What's Wrong with `flutter_terminal` (to fix)

| Problem                                              | Impact                                               |
| ---------------------------------------------------- | ---------------------------------------------------- |
| Top-level globals (`mSp`, `terminal`, `udpService`…) | Untestable, order-of-init bugs, hard to reason about |
| 40+ imports in `home_screen.dart`                    | Adding a panel requires touching 3 files             |
| `setState` in `HomeScreen` owns all navigation       | Can't deep-link, can't animate transitions           |
| `switch` in `_buildActivePanel()` grows unboundedly  | O(n) to add a panel                                  |
| No models — raw strings passed everywhere            | Parsing logic leaks into UI                          |

---

## Folder Structure (feature-first)

```bash
lib/
├── core/
│   ├── router/           # go_router config
│   ├── theme/            # AppColors, AppTheme, themeModeProvider
│   └── utils/            # app_logger, formatters, snackbars
│
├── services/             # Raw I/O — keepAlive Riverpod providers, no widgets
│   ├── serial_service.dart
│   ├── udp_service.dart
│   ├── pty_service.dart
│   └── file_logger_service.dart
│
├── features/             # One folder per user-facing feature
│   ├── connection/
│   │   ├── providers/    # ConnectionNotifier, SerialConfigNotifier, BoardProfileService
│   │   ├── widgets/      # ConnectionBar, BoardProfilePicker
│   │   └── models/       # (feature-local models if not shared)
│   ├── terminal/
│   │   ├── providers/    # terminal_instances (xterm Terminal objects)
│   │   └── widgets/      # LogPanel
│   ├── home/
│   │   └── widgets/      # MenuSidebar
│   ├── cmd_history/
│   ├── settings/
│   └── panels/
│       ├── common/       # StubPanel, NotFoundPanel
│       ├── models/       # PanelEntry
│       ├── nvidia/
│       ├── rockchip/
│       ├── diagnostics/
│       ├── esp/
│       ├── lte/
│       └── panel_registry.dart
│
└── shared/
    ├── widgets/          # MyPanel, InfoTile, ProgressBar, StatusBadge, buildDropdown
    └── models/           # SerialConfig, LogEntry, BoardCommand, BoardProfile
```

> **Key win:** Each feature is self-contained. Adding a new panel means creating one folder
> with its own provider, model, and widget — no changes to `home_screen.dart`.

---

## What Goes Where — Decision Guide

### `services/` — Raw I/O, no UI

Wraps hardware, sockets, or the file system directly. No Flutter widget imports.
These are `@Riverpod(keepAlive: true)` providers that own one resource each.

**Goes here:**

- Opening/closing a serial port (`SerialService`)
- Binding a UDP socket (`UdpService`)
- Spawning a PTY process (`PtyService`)
- Writing bytes to a log file (`FileLoggerService`)

**Does not go here:** Connection *state* (connected/disconnected), user-triggered logic,
anything that reacts to button presses. Those belong in `features/X/providers/`.

> **Test:** Would this class exist in a non-Flutter Dart CLI app? Yes → `services/`.

---

### `features/` — Business Logic + Feature UI

Each feature subfolder owns everything for one user-facing capability.
Internal layout: `providers/`, `widgets/`, and optionally `models/`.

#### `features/X/providers/`

Riverpod notifiers that translate user actions into state, using `services/` under the hood.

| File | Role |
| ---- | ---- |
| `connection_provider.dart` | Owns `Connected/Disconnected` state; calls `SerialService` |
| `serial_config_notifier.dart` | Owns current port / baud / encoding selection |
| `board_profile_service.dart` | Loads and saves profiles from Hive |
| `terminal_instances.dart` | Owns the `xterm.Terminal` and `TerminalController` instances |

> **Service vs provider:** `SerialService` *opens the port*. `ConnectionNotifier` *decides
> when to open it* and tracks whether it is open. Service = mechanism, provider = decision.

#### `features/X/widgets/`

UI that only makes sense inside that one feature. Has imports from its own `providers/`.

| File | Why it stays here |
| ---- | ----------------- |
| `connection_bar.dart` | Only meaningful in the connection feature |
| `log_panel.dart` | Only meaningful in the terminal feature |
| `menu_sidebar.dart` | Only meaningful in the home screen layout |

> **Test:** If you deleted the entire `features/connection/` folder, would widgets from
> *other* features break? If yes, the broken parts belong in `shared/` instead.

---

### `shared/` — Reused Across Multiple Features

#### `shared/widgets/`

Generic UI components with zero feature-specific logic.
No imports from any `features/` subfolder.

| Widget | Why it is shared |
| ------ | ---------------- |
| `MyPanel`, `PanelHeader`, `PanelBody` | Used by every panel — nvidia, rockchip, esp, diagnostics |
| `InfoTile`, `ProgressBar`, `StatusBadge` | Generic display components used across panels |
| `buildDropdown`, `ToolbarDivider` | Generic toolbar primitives |

#### `shared/models/`

Freezed data models referenced by more than one feature.

| Model | Why it is shared |
| ----- | ---------------- |
| `SerialConfig` | Used by `connection/` (configure) and `services/` (open port) |
| `BoardProfile` | Used by `connection/` (save) and panels (read current target type) |
| `LogEntry` | Consumed by `terminal/` and written by `services/` |
| `BoardCommand` | Shared between panels and the command-history feature |

> **Feature-local vs shared:** Start a model in `features/X/models/`. Move it to
> `shared/models/` the moment a second unrelated feature needs to import it.

---

### `core/` — App Infrastructure

Things the whole app depends on that are not a user-facing feature.

| Folder | Contents |
| ------ | -------- |
| `core/router/` | `go_router` config, route definitions |
| `core/theme/` | `AppColors` (ThemeExtension), `AppTheme`, `themeModeProvider` |
| `core/utils/` | Pure utilities: `stripAnsi`, byte converters, `log`, `showSnackbar` |

> **Core vs shared:** `core/` is the skeleton the app cannot run without (router, theme).
> `shared/` is reusable bricks that features build with.
> A theme color → `core/`. A panel card layout → `shared/`.

---

## Package Stack

### State Management

```yaml
flutter_riverpod: ^2.6.1
riverpod_annotation: ^2.4.1    # code-gen for providers
riverpod_lint: ^2.3.13         # catches provider mistakes at compile time
```

Riverpod over Provider/Bloc because:

- Providers are compile-time safe (no `context.read<T>()` magic strings)
- `AsyncNotifier` + `StreamProvider` map perfectly to serial/UDP streams
- `riverpod_annotation` removes boilerplate with `@riverpod` codegen

### Routing

```yaml
go_router: ^14.6.3
```

Replace the `switch` panel system with named routes:

```bash
/                    → connection screen (if not connected)
/home                → main shell
/home/panel/:panelId → deep-linkable panels
```

The sidebar just calls `context.go('/home/panel/nv_gpio')` — no more switch.

### Immutable Models

```yaml
freezed: ^2.5.7
freezed_annotation: ^2.4.4
json_serializable: ^6.9.4
build_runner: ^2.4.15
```

Example:

```dart
@freezed
class SerialConfig with _$SerialConfig {
  const factory SerialConfig({
    required String port,
    @Default(115200) int baudRate,
    @Default(Encoding.utf8) Encoding encoding,
    @Default(NewLine.lf) NewLine newLine,
  }) = _SerialConfig;
}
```

Replaces `gSelectedEncoding` / `gSelectedNewLine` globals.

### UI & Layout

```yaml
multi_split_view: ^2.3.0    # resizable log panel splitter
```

The current log panel resizing is manual; `multi_split_view` gives drag-to-resize with saved state.

### Persistence

```yaml
shared_preferences: ^2.5.5  # simple KV — keep as-is
```

Or upgrade to:

```yaml
hive_ce: ^2.9.0             # typed, fast, no codegen required
```

Hive is better if you store structured data (saved commands, board profiles).

### Keep from `flutter_terminal`

```yaml
flutter_libserialport: ^0.6.0
flutter_pty: ^0.4.2
xterm: ^4.2.0               # use pub.dev version — no local path hack
window_manager: ^0.5.1
file_picker: ^10.3.10
```

### Nice Additions for Public Release

```yaml
logger: ^2.5.0              # replaces mUtils print() calls
package_info_plus: ^8.1.2   # show app version in About
flutter_localizations:      # i18n for non-English users
  sdk: flutter
```

---

## State Architecture (Riverpod)

Replace all globals with typed providers:

```dart
// services/serial_service.dart
@Riverpod(keepAlive: true)
SerialService serialService(Ref ref) => SerialService();

// features/connection/providers/connection_provider.dart
@riverpod
class ConnectionNotifier extends _$ConnectionNotifier {
  @override
  ConnectionState build() => const ConnectionState.disconnected();

  Future<void> connect(SerialConfig config) async { ... }
  void disconnect() { ... }
}

// features/terminal/providers/terminal_provider.dart
@riverpod
class TerminalNotifier extends _$TerminalNotifier {
  @override
  TerminalState build() { ... }
}
```

Panels become pure consumers:

```dart
class NvGpioPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(connectionNotifierProvider
      .select((s) => s is Connected));
    // no global access needed
  }
}
```

---

## Panel Registry (replaces the switch)

```dart
// features/panels/panel_registry.dart
final panelRegistry = <String, Widget Function()>{
  'nv_gpio':         () => const NvGpioPanel(),
  'nv_hdmi':         () => const NvHdmiPanel(),
  'rc_gpio':         () => const RcGpioPanel(),
  'diagnostics_cpu': () => const DnCpuPanel(),
  // ...
};
```

The router resolves the panel automatically:

```dart
GoRoute(
  path: '/home/panel/:panelId',
  builder: (ctx, state) {
    final id = state.pathParameters['panelId']!;
    return panelRegistry[id]?.call() ?? const NotFoundPanel();
  },
)
```

Adding a panel = add one line to the map. Zero changes to `home_screen.dart`.

---

## UI Design Upgrades

**Connection bar**
Show port + status as a persistent pill badge. Consider a bottom status bar (VS Code style):

```bash
COM3 | 115200 | UTF-8 | Connected ●
```

**Log panel**
Add tab support for multiple connections (serial + UDP side by side). `xterm` already supports multiple terminal instances.

**Sidebar**
Keep the current collapsible group design (it works well), but drive it from the registry so groups are also data-driven rather than hardcoded.

**Board profile system**
Let users save a board config (port, baud, IP, target type: nvidia/rockchip/esp) and restore it on launch. This makes the app genuinely useful to others on GitHub.

---

## Minimal Package Set to Start

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.4.1

  # Routing
  go_router: ^14.6.3

  # Models
  freezed_annotation: ^2.4.4
  json_serializable: ^6.9.4

  # Hardware I/O
  flutter_libserialport: ^0.6.0
  flutter_pty: ^0.4.2
  xterm: ^4.2.0

  # Window / Platform
  window_manager: ^0.5.1

  # Storage
  shared_preferences: ^2.5.5

  # UI
  multi_split_view: ^2.3.0

  # Logging
  logger: ^2.5.0

  # Utils
  package_info_plus: ^8.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.15
  riverpod_generator: ^2.4.3
  riverpod_lint: ^2.3.13
  freezed: ^2.5.7
  flutter_lints: ^5.0.0
```

---

## Priority Order

The three changes with the biggest return on investment:

1. **Riverpod** — eliminates all top-level globals
2. **go_router + panel registry** — eliminates the `switch` and all the imports
3. **Freezed models** — eliminates raw string passing between layers