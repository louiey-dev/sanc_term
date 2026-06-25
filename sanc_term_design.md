# sanc_term — Architecture & Design Guide

This app is updated version of flutter_terminal(D:\GIT\Flutter\flutter_terminal).
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
│   ├── theme/            # AppColors, AppTheme
│   └── utils/            # formatters, ANSI stripper
│
├── services/             # I/O singletons, exposed via Riverpod
│   ├── serial_service.dart
│   ├── udp_service.dart
│   └── pty_service.dart
│
├── features/
│   ├── connection/       # port selection, baud, connect state
│   │   ├── providers/
│   │   ├── widgets/
│   │   └── models/
│   ├── terminal/         # xterm log panel
│   │   ├── providers/
│   │   └── widgets/
│   ├── cmd_history/
│   ├── settings/
│   └── panels/
│       ├── common/
│       ├── nvidia/
│       ├── rockchip/
│       ├── diagnostics/
│       ├── esp/
│       └── panel_registry.dart   ← replaces the big switch
│
└── shared/
    ├── widgets/          # MyPanel, InfoTile, StatusBadge
    └── models/           # BoardCommand, LogEntry
```

> **Key win:** Each feature is self-contained. Adding a new panel means creating one folder with its own provider, model, and widget — no changes to `home_screen.dart`.

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
