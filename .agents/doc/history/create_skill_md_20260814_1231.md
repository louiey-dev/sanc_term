# sanc_term SKILL.md Creation Report

- Date: 2026-08-14 12:31:00
- Purpose: Document codebase architecture, directory structure, features, and runbooks into `SKILL.md`.

## Summary of Changes

1. Created [.agents/skills/sanc-term/SKILL.md](file:///D:/GIT/GitHub/sanc_term/.agents/skills/sanc-term/SKILL.md) following the Antigravity workspace skills specification.
2. Created [SKILL.md](file:///D:/GIT/GitHub/sanc_term/SKILL.md) in the project root for reference.
3. Included comprehensive technical guidelines:
   - **Layering rules**: `services/` (raw I/O), `features/` (business logic & UI), `shared/` (widgets & Freezed models), `core/` (router & theme).
   - **Panel Registry & Navigation**: `PanelEntry` $\rightarrow$ `panel_registry.dart` $\rightarrow$ `app_router.dart`.
   - **Multi-pane Terminal & Serial transport**: `TerminalTabsNotifier` + `SerialPaneNotifier.family`.
   - **Board Console commands**: `ConsoleCommandSession.run()` output capture and `sendBoardCommand()` fire-and-forget.
   - **Step-by-step Runbooks**: Adding new panels, creating Freezed models, executing CLI build/test workflows.
