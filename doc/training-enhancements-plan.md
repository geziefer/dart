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

### A2 — Heatmap / grouping visualization
- [ ] Board-image overlay widget rendering actual landings (x/y) for a session
      and/or aggregated across sessions, filterable by game/target.
- [ ] Entry point (e.g. from the stats page or a game's trophy area).
- [ ] Widget tests for rendering with sample data; graceful empty state.

### A3 — Accuracy metrics
- [ ] Derive mean radial error, scatter/std-dev (mm), and directional bias for
      target games where the intended segment is known.
- [ ] Surface inner-vs-outer single tendency (A4 folded in via `isOuterSingle`).
- [ ] Show in stats/summary; tests for the math.

**✅ Checkpoint A:** analyze clean · full suite green · device-tested with real
board data where possible · docs updated · **commit + bump to v3.2.0**.

---

## Step B — Adaptive practice & motivation  → v3.3.0

**Goal:** Turn accumulated stats/throw-log into a feedback loop and light
motivation layer.

### B1 — Weakness-targeted drills
- [ ] Compute weakest numbers/doubles from stats (and A1 data when available).
- [ ] Generate a focused drill session targeting them, reusing existing game
      logic (e.g. dynamic "worst 3 doubles").
- [ ] Tests for weakness selection + drill generation.

### B2 — Per-game trend view
- [ ] Sparkline/trend of recent sessions per game (uses long-term stats; richer
      with A1).
- [ ] Add to the stats page; widget test.

### B3 — Daily/weekly goals & streaks
- [ ] Lightweight "trained today / this week" tracker + streak counter on the
      menu. No new infra.
- [ ] Tests for streak rollover edge cases (day boundaries).

**✅ Checkpoint B:** analyze clean · full suite green · device-tested · docs
updated · **commit + bump to v3.3.0**.

---

## Step C — Session & flow  → v3.4.0

**Goal:** Smoother multi-game sessions and better end-of-session feedback.

### C1 — Routine / playlist mode
- [ ] User-defined chain of games played back-to-back (generalize the Challenge
      controller's proven sub-controller-sequencing pattern).
- [ ] Persist a few named routines.
- [ ] Tests for sequencing + completion.

### C3 — Session summary at exit
- [ ] On leaving a game, show "this session vs. your average / your best" recap
      (presentation over existing numbers).
- [ ] Widget test for the recap.

**✅ Checkpoint C:** analyze clean · full suite green · device-tested · docs
updated · **commit + bump to v3.4.0**.

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
