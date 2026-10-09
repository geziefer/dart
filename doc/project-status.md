# DART — Project Status & Session Orientation

> Purpose: a fast, session-independent "start here" so anyone (human or AI)
> can rebuild context in a minute. For deep detail see the linked docs.
> Keep this file short and current.

## What this is

**DART — "Damit Alex Richtig Trainiert"** — a personal, single-player darts
**training** app built in Flutter. Optimized for one device (Google Pixel C
tablet, landscape). No public/multi-user concerns; the single user knows the
rules, so no "dummy-proofing" is needed.

- **Framework:** Flutter / Dart (SDK `>=3.0.0 <4.0.0`)
- **State management:** Provider (`ChangeNotifier` controllers)
- **Persistence:** `get_storage` (local key-value, per-game IDs) — no network DB
- **Architecture:** Service-oriented MVC (controller / view / widget / service)

## Current state (verified 2026-09-17)

- Branch `main`, working tree clean. Latest commit merges the Scolia integration
  as **v3.0.0**.
- `flutter analyze` → **No issues found.**
- Test suite: 33 test files under `test/` (docs report ~415 tests green).
- **Scolia Home 2 integration is COMPLETE** (all phases A–H). Real board
  validated (External API v1.4). This was the major recent workstream.
- **Per-game Top-10 highscores (v3.1.0):** each supporting game keeps a dated
  Top-10 list of its best single-game result in its own storage container under
  the `highscores` key. Logic in `lib/services/highscore_service.dart`
  (`HighscoreEntry`, `highscoreConfigs` per game id, `HighscoreService` with
  strict-better insertion; equal values allowed as separate dated entries but
  never displace an equal earlier one). `ControllerBase.recordHighscore(...)`
  is called from each game's `updateSpecificStats`; `lastHighscoreRank` drives a
  🏆 summary line. A trophy in `GameLayout`'s stats area opens
  `HighscoreDialog` (ranks 1–10). The stats page shows rank #1 inline + an
  expandable 2–10 section. Export/import is version `2.0` (highscores as a JSON
  array). `tool/migrate_highscores.dart` upgrades an old v1.0 export in place
  (1 synthesized entry per game). The Quiz (`FQ`) has no highscore; the
  Sportabzeichen (`CHALLENGE`) stores its awarded medal (failed runs excluded).

## The two big subsystems

### 1. Training games (the core app)
~22 single-player training games. Each game is one `MenuItem` wiring a
**controller** (`lib/controller/controller_*.dart`) to a **view**
(`lib/view/view_*.dart`). Shared UI lives in `lib/widget/`, business logic in
`lib/services/` (`StatsService`, `StorageService`, `SummaryService`,
`HighscoreService`, and `ThrowLogService` — the in-memory per-dart throw-log
analytics layer added in v3.2.0, backed by the `throw_log` get_storage
container).

Every game: rounds → summary dialog → stats persisted → back to menu.
Layout convention: logo on top; left = results table/text; right = input
(numpad, or full dartboard for some games); bottom = per-game + overall stats.

### 2. Scolia input mode (second global input source)
A Scolia Home 2 autoscoring board acts as a pure **input sensor** feeding the
*existing* game logic — the numpad stays the default and remains available for
manual correction. Code lives in `lib/scolia/`.

Key principle: **translate, don't fork.** Each supporting controller implements
`ScoliaController.submitScoliaTurn(TurnResult)` and interprets raw darts against
its own current goal, reusing the same state mutation the numpad path uses.
Equivalence tests prove numpad and Scolia paths produce identical state.

Pipeline: `ScoliaConnection`/`MockScoliaSource` → `SectorParser` →
`TurnCollector` → `ScoliaInputAdapter` → `controller.submitScoliaTurn`.
A global **Scolia toggle** (start menu) and a **Simulator** switch + **Monitor**
(settings page) allow full testing without a physical board.

## Where things live

```
lib/
├── main.dart              # entry: providers, ScoliaService, orientation
├── styles.dart            # global styles (reusable text styles etc.)
├── controller/            # one controller_*.dart per game + controller_base
├── view/                  # one view_*.dart per game + stats/scolia views
├── widget/                # menu, numpad, dartboard (fullcircle), dialogs, ...
├── services/              # StatsService, StorageService, SummaryService
├── interfaces/            # MenuitemController, NumpadController, DartboardController
├── utils/                 # responsive, stats_formatter, web helpers
└── scolia/                # Scolia input subsystem (protocol/, models/, service)
```

## Build & test

```bash
flutter analyze                       # must stay clean
flutter test                          # full suite
flutter test test/<game>_widget_test.dart
dart run build_runner build           # regenerate *.mocks.dart when deps change
flutter run                           # run on device/simulator
flutter build apk                     # Android (primary target)
```

Conventions worth remembering (see `.amazonq/guidelines.md`):
- No UI code in controllers; reusable styles go in `styles.dart`.
- `final` over `var`; public API gets `///` doc comments; run `dart format`.
- Don't preface corrections with "You're absolutely right" — just fix it.

## Adding a new game (established pattern)

1. `controller_<name>.dart` extends `ControllerBase`, implements
   `MenuitemController` + `NumpadController` (+ `ScoliaController` if Scolia-supported).
2. `view_<name>.dart` — standard layout; input slot is
   `scoliaInputActive(context) ? ScoliaDartboard(...) : Numpad(...)`.
3. Register controller in `main.dart` provider tree; add a `MenuItem` in `menu.dart`.
4. Add `<name>_widget_test.dart` (+ generated mocks). For Scolia games add an
   equivalence test proving Scolia == numpad state.

## Reference docs

- `doc/developer-documentation.md` — full architecture & patterns.
- `doc/widget-tests-documentation.md` — per-game test coverage.
- `doc/scolia-integration-concept.md` — original design rationale.
- `doc/scolia-implementation-plan.md` — authoritative Scolia task tracker
  (all A–H checked off) + per-game translation rules. **Update its checkboxes
  if Scolia work resumes.**
- `doc/training-enhancements-plan.md` — **authoritative roadmap & task tracker
  for upcoming features** (v3.1.1 → v3.4.0). Start here when resuming feature
  work; check off tasks and tick the per-step checkpoints.
- `.amazonq/{context,architecture,guidelines}.md` — business rules, domain
  terms, coding standards.

## Likely next work (planned roadmap)

See `doc/training-enhancements-plan.md` for the full plan. Sequence, each a
separate feature with its own checkpoint (analyze+test+device), commit, and
version bump:

1. **v3.1.1 — C2 ✅ DONE:** Scolia per-value post-submit correction — correct a
   dart in the last submitted round (undo-round + re-submit edited turn in
   `ScoliaDartboard`; equivalent by construction, local only).
2. **v3.2.0 — A ✅ DONE (pending real-board validation):** throw-log analytics.
   - **A0 ✅** storage decision: *keep `get_storage`* + an in-memory analytics
     layer; drift/SQLite rejected (Android 8 + web native-sqlite risk, overkill
     for single-user volume).
   - **A1 ✅** per-dart throw log: `ThrowLogService` (loaded at startup, queried
     in memory) backed by a dedicated `throw_log` container; `LoggedDart`/
     `ThrowSession` model; Scolia darts (incl. x/y/angle + intended target)
     captured in `ScoliaDartboard` and flushed once per session on dispose;
     platform-adaptive quota-aware eviction (web evicts oldest; Android keeps all).
   - **A2 ✅** heatmap/grouping viz: `HeatmapView` (CustomPaint board + plotted
     x/y landings) opened per game from the stats page (scatter-plot icon).
   - **A3 ✅** accuracy metrics: `DartTarget`/`BoardGeometry` + per-controller
     `AimTargetReporting` (intended target per dart) + `ThrowAccuracy` (distance
     to target, scatter σ, directional bias in mm/clock, inner/outer single
     share; ≥2-sector exclusion). Shown in the heatmap metrics panel.
   - **Pending on real board:** coordinate y-orientation (`flipY`) + mm scale.
3. **v3.3.0 — B ✅ DONE:** adaptive practice & motivation.
   - **B1 ✅** `WeaknessService` + `DrillService`: rank weakest targets from the
     throw log and suggest focus drills (shown in the heatmap panel; dormant
     until real-board throw-log data exists).
   - **B2 ✅** `ResultHistoryService` (dated per-game results, numpad+Scolia,
     recorded with the highscore) + `TrendSparkline` on the stats page.
   - **B3 ✅** `StreakService` + `StreakBadge` on the menu (consecutive-day
     streak, trained-today, days/7) from the union of played-dates.
4. **v3.4.0 — C:** session & flow (user-defined routines, exit recaps).
