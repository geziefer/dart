# Training Enhancements — Implementation Plan & Task Tracker

This document is the **authoritative, session-independent** plan for the next
wave of DART improvements: using the rich per-dart data the Scolia board
produces to turn the app from a *score tracker* into a *training analyst*, plus
adaptive practice and session-flow features.

Keep this file updated: **check off tasks as they are completed** and tick the
checkpoint when each feature is tested and committed. If a session is
interrupted, start here.

> Scope reminder: this stays a **private, single-player training app**. No
> multiplayer, accounts, or cloud/social features. Scolia remains a pure input
> sensor (receive-only; corrections stay local).

---

## 0. Guiding insight

The numpad records *what you scored*. The Scolia board additionally knows
*where each dart physically landed* — `DetectedThrow` already carries
`segment`, `ring`, resolved `value`, inner-vs-outer single, and optional
`x`/`y` (mm from centre, ±250) and `angle`. Today that spatial data is scored
and then **discarded**; nothing persists a per-dart history. Capturing it is the
keystone that unlocks accuracy analytics, heatmaps, and adaptive drills — things
a numpad can never provide.

## 1. Version & feature map

Current baseline: **v3.1.0+23** (per-game Top-10 highscores).

| Step | Feature | Version | Theme |
|------|---------|---------|-------|
| C2   | Scolia per-value post-submit correction | **v3.1.1** (patch; part of current line) | Finish the existing Scolia backlog |
| A    | Throw log + accuracy metrics + heatmap (incl. optional storage refactor) | **v3.2.0** | Unlock Scolia-unique data |
| B    | Adaptive practice & motivation layer | **v3.3.0** | Make practice adaptive |
| C    | Session & flow (routines, exit recaps) | **v3.4.0** | Smoother training sessions |

Each step is a self-contained feature with its **own checkpoint**: run
`flutter analyze` + full `flutter test`, verify on device, then a **separate
commit** (and version bump) before starting the next step.

---

## Step C2 — Scolia per-value post-submit correction  → v3.1.1

**Goal:** Allow correcting an individual already-scored dart in the current/last
round when the board misreads a dart, instead of only whole-round undo.

Tasks:
- [x] Review current whole-round undo path and `ScoliaController.submitScoliaTurn`
      state mutation per supporting game.
- [x] Design a minimal per-dart correction UI (tap a scored dart in the round →
      choose corrected sector) reusing the existing correction entry points.
      Keep corrections **local** (no `THROW_CORRECTED` sent to Scolia).
- [x] Implement correction in the shared path so every Scolia-supported game
      inherits it (translate, don't fork).
- [x] Equivalence tests: corrected state == state as if the right dart had been
      entered originally, for a representative set of games.
- [x] Update `doc/scolia-implementation-plan.md` (remove this from "remaining
      optional improvements").

**✅ Checkpoint C2:** analyze clean · full suite green · device-tested (pending
hardware) · `doc` updated · **commit + bump to v3.1.1**.

**Implementation note:** post-submit correction lives entirely in
`ScoliaDartboard`. The just-submitted turn is retained and shown as a dimmed
"committed" round; tapping a committed dart undoes the whole round via the
existing `onUndoRound`, reloads the turn into the collector for editing, and the
takeout/confirm (check icon) re-submits the edited turn through
`submitScoliaTurn`. Equivalent by construction; no controller changes; single
round-undo depth. Tests: 3 cases in `test/scolia_ui_test.dart` (x01 score,
no-undo guard, RTCS count-based).

---

## Step A — Throw log, accuracy metrics & heatmap  → v3.2.0

**Goal:** Persist per-dart data and surface it as real precision analytics and a
visual heatmap. The high-value payoff of owning a camera board.

### A0 ✅ DONE — Storage decision: keep `get_storage` + in-memory analytics layer

**Decision (made 2026-10-08): no storage-technology change.** We keep
`get_storage`/`StorageService` for everything (existing stats/highscores/
import-export AND the new throw log). We add an in-memory analytics layer loaded
at startup.

**Why not drift/SQLite (evaluated and rejected):**
- The only reason to switch was better *queries* over per-dart rows. But the
  data is single-user and bounded, so loading everything into memory at startup
  and querying in pure Dart is more than fast enough.
- `sqflite` has no web support; `drift` works on web but needs a
  `sqlite3.wasm` + worker and the current `sqlite3` v3 stack uses experimental
  build hooks with a newer SDK floor and **drops the old-Android workaround** —
  a real risk for the **Pixel C (Android 8)** primary device. Not worth it.
- `hive` would work everywhere but is still key-value, so it buys nothing over
  `get_storage` for our query needs.

**Architecture:**
- **Persistence:** a dedicated `throw_log` `get_storage` container holding a list
  of per-**session** records. Written **once at game/session end** — never per
  dart (no hot-path writes).
- **In-memory:** a `ThrowLogService` loads all sessions at startup into
  query-friendly structures (indexed per game / per target) for A2/A3. All
  queries hit memory; pure Dart (`where`/`fold`/`groupBy`). Provider-registered
  like the other services, initialized in `main()` after `GetStorage.init`.
- **Capture:** a session accumulates its darts during play; on game/session end
  (the existing end-of-game lifecycle) it is appended to the in-memory list and
  persisted.

**Platform-adaptive eviction (no fixed cap):**
- Writes go through a **quota-aware helper**: attempt the write; on web, a
  `localStorage` `QuotaExceededError` triggers dropping the **oldest** whole
  session(s) and retrying, repeating until it fits or the log is empty. Pruning
  is oldest-first (FIFO) and logged — never silent.
- **Android** (file-backed, no small quota) effectively never prunes → primary
  devices keep full history. **Web** (localStorage ≈ 5 MB) self-limits to
  whatever fits. The **same quota-aware path** is reused when importing an
  exported session, so an over-large import caps web by evicting oldest.

**Rough sizing:** ~50 bytes/dart with x/y/angle → ~10 KB per 200-dart session.
Web ≈ 5 MB localStorage ≈ ~500 sessions before eviction kicks in; Android far
more. Daily training = well over a year on web before any pruning.

### A1 ✅ DONE — Persist a per-dart throw log (foundational)
- [x] New model + store for session throw records: `LoggedDart`/`ThrowSession`
      (`lib/services/throw_log_model.dart`, compact JSON) persisted via
      `ThrowLogService` (`lib/services/throw_log_service.dart`) in a dedicated
      `throw_log` get_storage container. Scolia sessions carry x/y/angle.
- [x] Hook capture into the Scolia pipeline without changing scoring: darts are
      accumulated in `ScoliaDartboard` and flushed once as one `ThrowSession`
      on dispose (session end). Undo/post-submit-correction trim the log to
      match game state. All 17 Scolia views pass `gameId: controller.item?.id`.
- [x] Respect storage limits: platform-adaptive quota-aware write — on web
      `QuotaExceededError`, evict oldest (FIFO) and retry; Android keeps all.
      (Async persist catches both sync throws and Future rejections.)
- [x] Tests: `throw_log_service_test.dart` (load/round-trip/queries/quota
      eviction/clear) + `throw_log_capture_widget_test.dart` (capture→flush on
      dispose; no-gameId no-op). Full suite green (445); `flutter build web` ok.
- [ ] (Later) Numpad-path capture, if/when desired (currently Scolia only).

### A2 ✅ DONE — Heatmap / grouping visualization
- [x] Board overlay widget (`lib/widget/heatmap_view.dart`, `HeatmapView` +
      `_HeatmapPainter`) rendering actual landings (x/y) aggregated across all
      sessions of a game. Pure Flutter CustomPaint — board backdrop (edge +
      double/treble/bull reference rings + 20 slice dividers), translucent dots
      coloured by ring; overlap stacks into a density "heat". No deps.
      (Per-target filtering can come later.)
- [x] Entry point: a scatter-plot icon per game card on the stats page opens a
      dialog with the game's heatmap, reading `ThrowLogService.dartsForGame`.
- [x] Widget tests (`test/heatmap_view_test.dart`): empty state (no coords /
      empty list), populated render + count footer, coords-only counting.
- [ ] (Note) Board y-axis orientation uses a single `flipY` flag; validate
      against the real Scolia board (coordinates not available in simulator).
### A3 ✅ DONE — Accuracy metrics
Per-game aiming model: an intended target is recorded **per dart** only where
the game defines one; free-choice phases (x01 scoring, Credit Finish round 1)
record no target. Grouping/bias is meaningful where darts repeat a target;
distance-to-target applies wherever a target is known.
- [x] `DartTarget` + `BoardGeometry` (`lib/services/dart_target.dart`): intended
      aim point → geometric sector centre in mm. Rules: unspecified single →
      big single; scoring-to-number → triple; scoring-to-centre → double bull.
- [x] Each supporting controller reports per-dart targets via the optional
      `AimTargetReporting` capability (killbull/speedbull → bull; shootx →
      T(x)/bull; bobs27 → round double; bigts → T20/T19/T18; doublepath → round
      doubles; planhit → round singles; rtcx → single/double/triple of the
      running number by mode; acrossboard → per-dart D/T/big-single/small-single
      /bull; twodarts → single+bull; halfit → number triple or ring-only for
      the arbitrary D/T rounds; xxxcheckout/creditfinish-r2/check121 → the
      required double only when the remaining is a direct double finish).
- [x] `ThrowAccuracy` (`lib/services/throw_accuracy.dart`): mean distance to
      target (+σ), directional bias (mm + clock), inner/outer single share.
      Darts ≥ 2 sectors from their target are excluded (setups/strays); misses
      carry no coordinates so are excluded automatically.
- [x] Shown in the heatmap dialog metrics panel; tests:
      `throw_accuracy_test.dart` (math/geometry/exclusion) +
      `target_reporting_test.dart` (per-controller target selection).

**✅ Checkpoint A:** analyze clean · full suite green (471) · `flutter build
web` ok · device validation of coordinate orientation (`flipY`) + mm scale
still pending on real board · docs updated · **commit + bump to v3.2.0**.

---

## Step B — Adaptive practice & motivation  → v3.3.0

**Goal:** Turn accumulated stats/throw-log into a feedback loop and light
motivation layer.

### B1 ✅ DONE — Weakness-targeted drills
- [x] `WeaknessService` ranks the weakest targets from the throw log (grouped by
      intended `DartTarget`, by hit-rate then mean distance, with a minimum
      attempts threshold; strays ≥ 2 sectors excluded).
- [x] `DrillService.suggestDrill` turns the worst targets into labelled focus
      suggestions (e.g. `T19 (20%)`), shown in the heatmap metrics panel
      ("Üben"). Dormant until real board data populates the throw log.
- [x] Tests: `weakness_service_test.dart`, `drill_service_test.dart`.

### B2 ✅ DONE — Per-game trend view
- [x] `ResultHistoryService`: a dated per-game result history (one entry per
      completed game, recorded alongside the highscore — works for numpad and
      Scolia), bounded for quota safety.
- [x] `TrendSparkline` renders the recent results; shown per game on the stats
      page ("Verlauf"), oriented by the game's higher-is-better config.
- [x] Tests: `trend_sparkline_widget_test.dart` + history round-trip/bounding
      in `streak_service_test.dart`.

### B3 ✅ DONE — Daily/weekly goals & streaks
- [x] `StreakService` derives the current consecutive-day streak, trained-today,
      and days-this-week from the union of all games' played-dates (from the
      result history — no new store).
- [x] `StreakBadge` on the start menu (flame + streak + days/7), hidden when
      there's no activity.
- [x] Tests: `streak_service_test.dart` (rollover, gaps, cross-game union, week
      boundary) + `streak_badge_widget_test.dart`.

**✅ Checkpoint B:** analyze clean · full suite green · docs updated ·
device-testing of B1 drills pending real-board throw-log data ·
**commit + bump to v3.3.0**.

---

## Step C — Session & flow  → v3.4.0

**Goal:** Smoother multi-game sessions and better end-of-session feedback.

### C1 ✅ DONE — Routine / playlist mode (category-based)
- [x] `RoutineGenerator` builds a routine by picking one random game from each
      of three fixed categories (scoring: 99x20 / Kill Bull / 501×5-max7;
      single-setup: Plan Hit / RTC Single / Cricket; checkout: Catch 40 /
      Bob's 27 / Double Path). Randomness gives varied sessions within defined
      categories — no editor needed.
- [x] `ActiveRoutine` (in-memory) tracks position; the menu `RoutineBar` shows
      a "Routine starten" button (idle) that generates+launches a fresh triplet,
      and a "next up" prompt (active) through the three games. Each game runs
      its normal flow; launch reuses normal navigation.
- [x] **Decline marker:** `DeclineService` flags a game whose recent results
      got worse (recent vs. previous window average, oriented by
      higher-is-better, relative margin). Declining games show a subtle
      down-arrow on their menu tile — a nudge to practise them.
- [x] Tests: `routine_bar_widget_test.dart` (generator + bar),
      `active_routine_test.dart` (progression), `decline_service_test.dart`,
      `menu_decline_marker_test.dart`.

### C3 ✅ DONE — Session summary at exit
- [x] The end-of-game summary dialog now appends a recap — "Diese Session" vs.
      "Bestwert" and "Ø letzte" — computed in `recordHighscore` from the
      highscore + result history (prior best/average, excluding the current
      game) and shown via `SummaryService.createRecapLines`.
- [x] Tests: `session_recap_test.dart` (formatting, null-handling, population).

**✅ Checkpoint C:** analyze clean · full suite green (508) · docs updated ·
**commit + bump to v3.4.0**.

---

## Deferred / parked ideas (not scheduled)

- **D1/D2 export + checkout analytics:** extend export to include the throw log
  (v2.1) and add darts-at-double success analytics. Natural follow-ups to A1.
- Anything requiring a server, accounts, or multiplayer — out of scope by
  design.

## Working conventions (reminder)

- No UI code in controllers; reusable styles in `styles.dart`; `final` over
  `var`; `///` on public API; run `dart format`.
- Test-before-commit: `flutter analyze` must stay clean and `flutter test` must
  be green at every checkpoint.
- For each Scolia-touching game, keep the numpad==Scolia equivalence tests
  passing (translate, don't fork).
