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
- [ ] Review current whole-round undo path and `ScoliaController.submitScoliaTurn`
      state mutation per supporting game.
- [ ] Design a minimal per-dart correction UI (tap a scored dart in the round →
      choose corrected sector) reusing the existing correction entry points.
      Keep corrections **local** (no `THROW_CORRECTED` sent to Scolia).
- [ ] Implement correction in the shared path so every Scolia-supported game
      inherits it (translate, don't fork).
- [ ] Equivalence tests: corrected state == state as if the right dart had been
      entered originally, for a representative set of games.
- [ ] Update `doc/scolia-implementation-plan.md` (remove this from "remaining
      optional improvements").

**✅ Checkpoint C2:** analyze clean · full suite green · device-tested ·
`doc` updated · **commit + bump to v3.1.1**.

---

## Step A — Throw log, accuracy metrics & heatmap  → v3.2.0

**Goal:** Persist per-dart data and surface it as real precision analytics and a
visual heatmap. The high-value payoff of owning a camera board.

### A0 (optional, decide first) — Storage refactor off `get_storage`
- [ ] Decide: does the throw log justify moving to a row-friendly local store
      (`drift`/`sqflite` or `hive`) now? (Also silences the wasm/`dart:html`
      web-build warning.) If yes, do this **before** A1.
- [ ] If adopted: migrate existing per-game stats + highscores + import/export
      with a one-time migration; keep export/import working. Bump export schema
      only if the on-disk shape changes.

### A1 — Persist a per-dart throw log (foundational)
- [ ] New model + store for session throw records: per game, a bounded history
      (e.g. ring buffer of last N sessions) of `DetectedThrow`s incl. x/y/angle
      when present. Numpad sessions log scored value only; Scolia sessions log
      the full spatial record.
- [ ] Hook capture into the Scolia pipeline (and numpad path where meaningful)
      without changing scoring behaviour.
- [ ] Respect storage limits (bound size; document the cap).
- [ ] Tests: log write/read, bounding, and that scoring is unaffected.

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
