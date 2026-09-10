# Scolia Integration — Implementation Plan & Task Tracker

This document is the **authoritative, session-independent** plan for implementing
Scolia Home 2 as a second input mode in the DART app. It supersedes the
speculative parts of `scolia-integration-concept.md` now that the **official
Scolia External API v1.4** documentation is available (`doc/Scolia API-*.pdf`).

Keep this file updated: check off tasks as they are completed.

---

## 1. What we are building (in one paragraph)

A **second, global input mode** where a Scolia Home 2 board acts as a pure
**input sensor**: each detected dart drives the app's *existing* game logic
instead of the virtual numpad. The numpad remains the default and stays available
as a manual correction fallback. We build the **concrete** Scolia protocol layer
against the real v1.4 spec — no unnecessary abstraction — but drive it from a
**mock/simulator** event source until live board access (trial) is available.

## 2. Key decisions (locked)

1. **Concrete, not abstract.** Build directly against the real Scolia message
   shapes. Game controllers depend on a small internal domain model
   (`DetectedThrow`/`TurnResult`), not on Scolia DTOs — but there is no generic
   "pluggable input source" abstraction beyond what the mock/real split needs.
2. **Receive-only + one config message.** Scolia is input only. We do **not**
   send corrections back (`THROW_CORRECTED`/`DELETE_THROW`/`RESET_PHASE` are NOT
   used) — all corrections are local via the existing numpad/undo path. On
   connect we DO send `CONFIGURE_SBC { enableMessageForwardToScolia: false }`
   (not opt-in — always) so our throws never create phantom games in the Scolia
   cloud/app.
3. **No "start game" handshake needed.** Per the spec, a `Ready` board in phase
   `Throw` emits `THROW_DETECTED` for every dart with no Scolia-side game
   required. Our app's own game logic is the only scoring authority.
4. **Credentials are local-only, never in code/git.** `serialNumber` +
   `accessToken` are entered by the user at runtime and stored locally via the
   existing `StorageService` (get_storage). They live in the app's local data
   dir, never in the repo (this project is public on GitHub). Token field masked.
5. **Mock/simulator until trial.** All logic is developed and unit-tested against
   a simulator that emits **real-format** Scolia messages. Only live-board
   end-to-end testing is deferred to the 30-day trial.

## 3. Relevant facts from Scolia External API v1.4

- **Connect:** `wss://game.scoliadarts.com/api/v1/external?serialNumber=...&accessToken=...&forceConnect=false`
- **Envelope:** `{ "type": "UPPER_SNAKE", "id": "uuid-v4", "payload": {...} }`.
  Incoming ids required; outgoing ids we generate.
- **Status:** Offline, Updating, Initializing, Calibrating, Ready, Error.
- **Phase** (null unless Ready): Throw, Takeout.
- **Incoming messages we consume:** `HELLO_CLIENT` (initial status/phase),
  `SBC_STATUS`, `SBC_STATUS_CHANGED`, `THROW_DETECTED`, `TAKEOUT_STARTED`,
  `TAKEOUT_FINISHED` (has `falseTakeout`), `ACKNOWLEDGED`, `REFUSED`,
  `SBC_BOARD_AVAILABILITY_CHANGED`.
- **Outgoing we send:** `CONFIGURE_SBC { enableMessageForwardToScolia: false }`
  only. (Envelope supports others; we don't use them.)
- **THROW_DETECTED.payload.sector** string, regex
  `/(([SsDT])(20|1[0-9]|[1-9]))|25|Bull|None/`:
  - `S`/`s` = single (both map to segment × 1; `s` = inner single, `S` = outer
    single — value identical, distinction only positional).
  - `D` = double (×2), `T` = triple (×3).
  - `25` = outer bull (25), `Bull` = inner bull (50), `None` = no detection.
  - Also: `coordinates` [x,y] ±250mm, `angle` {h,v}, `bounceout` bool,
    `sectorSuggestions` (0–3 alt sectors), `detectionTime` ISO-8601.
  - `bounceout: true` or `sector: "None"` → treat as a **miss** (value 0).
- **Turn boundary:** `TAKEOUT_FINISHED` with `falseTakeout == false` closes the
  turn. `falseTakeout == true` = user stepped in but didn't remove darts → ignore.
- **Close codes:** 4000 pong timeout, 4100 bad serial, 4101 already connected,
  4102 bad token, 4103 suspended, 4104 replaced (forceConnect).

## 4. Game input semantics (unchanged from concept doc)

Three categories of `pressNumpadButton(value)` meaning:
1. **Score-value** (`xxxcheckout`): value = round score total. Scolia: sum darts.
2. **Direct hit-count** (`shootx`, `planhit`): value = # darts meeting a goal (0–3).
3. **Interpreted hit-count** (`bobs27`): value = # darts hitting current target
   (0–3); controller converts via its own scoring (doubles game, bull = 50).

Approach: **translate, don't fork.** Each supporting controller implements
`submitScoliaTurn(TurnResult)` and interprets raw darts against its own current
goal, reusing existing state mutation. Numpad path and Scolia path converge on
identical state (proven by tests).

## 5. Directory layout

```
lib/scolia/
├── protocol/
│   ├── scolia_message.dart        # envelope + typed incoming/outgoing messages
│   ├── sector_parser.dart         # "T20" -> DetectedThrow; s/S/D/T/25/Bull/None
│   └── board_state.dart           # BoardStatus + BoardPhase enums (spec-exact)
├── models/
│   └── detected_throw.dart        # DetectedThrow, DartRing, TurnResult (domain)
├── turn_collector.dart            # groups darts into a TurnResult (takeout-aware)
├── scolia_event_source.dart       # interface consumed by adapter (real + mock)
├── scolia_connection.dart         # real WebSocket client (v1.4) — [LIVE-DEFERRED test]
├── mock_scolia_source.dart        # simulator emitting REAL-format messages
├── scolia_input_adapter.dart      # wires source -> active ScoliaController
├── scolia_controller.dart         # ScoliaController interface (submitScoliaTurn)
├── scolia_settings.dart           # serial/token load/save via StorageService
└── input_mode.dart                # global InputMode (numpad|scolia) holder
```

Game code depends only on `models/` + `scolia_controller.dart`. Protocol/DTO
types never leak into controllers.

---

## 6. Task list

Legend: `[ ]` todo · `[x]` done · **(LIVE)** = needs trial board for full
verification (code written & mock-tested now).

### Phase A — Protocol layer (fully specifiable now)
- [x] **A1.** `board_state.dart`: `BoardStatus` (offline/updating/initializing/
  calibrating/ready/error) + `BoardPhase` (throw/takeout) enums with string
  parsing matching spec casing.
- [x] **A2.** `sector_parser.dart`: parse sector string → `DetectedThrow`
  (segment, ring, value). Handle `s`/`S`/`D`/`T`, `25`, `Bull`, `None`. Pure fn.
- [x] **A3.** `scolia_message.dart`: envelope (`type`,`id`,`payload`) + typed
  parse for HELLO_CLIENT, SBC_STATUS(_CHANGED), THROW_DETECTED,
  TAKEOUT_STARTED/FINISHED, ACKNOWLEDGED, REFUSED, availability; + builder for
  outgoing CONFIGURE_SBC (and generic envelope w/ UUID v4).
- [x] **A4.** Unit tests for A1–A3 (sector parser exhaustively: every ring,
  bull cases, None, bounceout mapping; message parse round-trips).

### Phase B — Domain model + aggregation
- [x] **B1.** `models/detected_throw.dart`: `DetectedThrow`, `DartRing`,
  `TurnResult` (raw darts + `total`). Helpers: `isDoubleOf`, `hits`, `isBull`.
- [x] **B2.** `turn_collector.dart`: buffer darts, close turn on
  `TAKEOUT_FINISHED (!falseTakeout)`; also expose max-3-darts close; start clean
  on game entry; ignore throws while not in Throw phase.
- [x] **B3.** Unit tests for B1–B2 (turn grouping, takeout close, false-takeout
  ignore, <3-dart turns, bust/checkout mid-turn).

### Phase C — Event source (mock now, real transport deferred)
- [x] **C1.** `scolia_event_source.dart`: minimal interface —
  `Stream<DetectedThrow> throws`, `Stream<BoardStatus/Phase> state`,
  `connect()/disconnect()`. (Thin split so mock & real share one shape.)
- [x] **C2.** `mock_scolia_source.dart`: simulator that emits **real-format**
  messages (scripted sequences, e.g. "throw T20,T20,T20 then takeout"); usable in
  tests and for manual play without a board.
- [x] **C3. (LIVE)** `scolia_connection.dart`: real WSS client — URL+query auth,
  HELLO_CLIENT handshake, ping/pong + close-code handling/reconnect, sends
  CONFIGURE_SBC(false) on connect, parses incoming via A3. Injectable socket for
  tests with real-format JSON. Full e2e verification deferred to trial.
- [x] **C4.** Unit tests: mock source drives pipeline; connection parsing tested
  with injected fake socket + real-format JSON frames.

### Phase D — Controller integration (pilots)
- [x] **D1.** `scolia_controller.dart`: `ScoliaController` interface with
  `void submitScoliaTurn(TurnResult turn)`.
- [x] **D2.** `xxxcheckout` implements `submitScoliaTurn` (category 1: sum →
  existing enter path; respect bust/checkout rules already in controller).
- [x] **D3.** `bobs27` implements `submitScoliaTurn` (category 3: count darts
  that are `isDoubleOf(currentTarget)` incl. bull=inner → existing hits path).
- [x] **D4.** `scolia_input_adapter.dart`: subscribe to turn stream, route
  completed `TurnResult` to the active `ScoliaController`.
- [x] **D5.** Equivalence unit tests: for both pilots, a Scolia turn and the
  equivalent numpad input produce **identical controller state**.

### Phase E — Settings + input mode (UI)
- [x] **E1.** `scolia_settings.dart`: load/save `serialNumber`+`accessToken` via
  `StorageService` (local only; token masked in UI). Never committed.
- [x] **E2.** `input_mode.dart`: global `InputMode { numpad, scolia }` holder
  (ChangeNotifier or provider), default numpad.
- [x] **E3.** Stats page: rename title `Statistik` → `Statistik / Einstellungen`;
  add a 4th button **"Scolia"** to the existing button row → opens a Scolia
  settings page/dialog (serial + masked token fields + save; optional input-mode
  toggle + mock-connect for testing).

### Phase F — Verification
- [x] **F1.** `flutter analyze` clean.
- [x] **F2.** `flutter test` fully green (new + existing 307).
- [x] **F3.** Update this doc's checkboxes + note any items still (LIVE)-pending.

### Implementation status (as built)

All phases A–F implemented on branch `scolia_integration`. Verified: `flutter
analyze` clean; **361 tests pass** (307 existing + 54 new Scolia tests across
`test/scolia_protocol_test.dart`, `test/scolia_turn_collector_test.dart`,
`test/scolia_source_test.dart`, `test/scolia_equivalence_test.dart`).

Still to be wired when going live (small, deliberate follow-ups):
- The `InputModeHolder` and a live `ScoliaConnection` + `ScoliaInputAdapter` are
  not yet registered in `main.dart` / injected into game views. The pieces exist
  and are tested; hooking them into the running app (and swapping the active
  `ScoliaController` on game entry, plus a live/mock connect toggle) is the
  integration step to do at trial time.
- Only pilots `xxxcheckout` and `bobs27` implement `ScoliaController`. Remaining
  games get `submitScoliaTurn` rolled out after the pilots validate on hardware.

---

## 7. What remains genuinely blocked on the trial

Only **live-board end-to-end testing** of `scolia_connection.dart` (C3): real
auth handshake, real `THROW_DETECTED` timing, takeout behavior, reconnect against
the actual server. All parsing, aggregation, controller integration, settings,
and UI are built and unit-tested now via the real-format mock. When the trial
starts: enter credentials in the settings page, flip input mode to Scolia, and
validate C3 against the physical board — no further code expected beyond fixing
any wire-format surprises (which, given v1.4 is fully documented, should be
minimal and confined to `protocol/`).


---

## 8. Phase G — Dartboard input UI, simulator & monitor (live wiring)

Design agreed after reviewing the existing `finishes` dartboard (`FullCircle` +
`DartboardController.pressDartboard(String)` which already emits `T20`, `S1`,
`D16`, `DB`, `SB`). The Scolia input surface is the **dartboard**, unified across
simulator and real modes.

### Design (locked)

- **One input mode at a time** (no simultaneous numpad + Scolia). A global
  **"Scolia" toggle on the start menu** decides: ON → pilot games render the
  dartboard input; OFF → the normal numpad (unchanged behaviour).
- **`ScoliaDartboard` widget** = the reusable Scolia input surface:
  - Renders `FullCircle`.
  - Shows a **status/phase banner** (connection state + Ready/Throw/Takeout).
  - **Simulator mode:** the user's taps generate the throws.
  - **Real mode:** the board's `THROW_DETECTED` drives it and the hit field is
    **highlighted** (the screen mirrors the board).
  - Both feed the identical pipeline: sector → `SectorParser` → `TurnCollector`
    → adapter → `controller.submitScoliaTurn`.
  - This widget **doubles as the monitor** (state banner + highlighted hits +
    recent throws), so no separate monitor view is required — but a dedicated
    monitor entry in settings is still provided for board-without-app testing.
- **Simulator & Monitor live permanently in the Settings page** (expert view,
  single user). They do not interfere with the real setup:
  - **Simulator switch:** when ON, the source is `MockScoliaSource` (tap to
    throw). When OFF and credentials are present, the source is the real
    `ScoliaConnection`.
  - **Monitor:** a diagnostic screen using the dartboard + a **colour-coded**
    event log (states vs. throws vs. errors in distinct colours).
- Games/controllers stay logically untouched; only each pilot **view** gets a
  single uniform conditional in its input slot: `isScolia ? ScoliaDartboard
  : Numpad`. The `DB`/`SB` bull notation from `FullCircle` is normalised to
  Scolia's `Bull`/`25` at the widget boundary so the real pipeline is exercised.

### Tasks
- [x] **G1.** `ScoliaDartboard` widget: `FullCircle` + status/phase banner;
  implements `DartboardController`; normalises `DB`->`Bull`, `SB`->`25`; feeds
  taps (simulator) / highlights hits (real) through the pipeline.
- [x] **G2.** Menu: global **"Scolia" toggle** (uses `InputModeHolder`),
  persisted; shown on the start menu.
- [x] **G3.** Wire `main.dart`: register `InputModeHolder` + a source provider
  (mock vs. real chosen by the Simulator switch / credentials) + adapter.
- [x] **G4.** Pilot views (`view_xxxcheckout`, `view_bobs27`): swap input slot
  to `ScoliaDartboard` when `InputModeHolder.isScolia`, else `Numpad`.
- [x] **G5.** Settings page: add a **Simulator** switch (mock vs. real source)
  and a **Monitor** entry (colour-coded state/throw/error log; reuses the
  dartboard for hit display).
- [x] **G6.** Tests: simulator taps drive a pilot game on-screen (e.g. simulated
  180 drops x01 remaining by 180); monitor renders a real-format frame with the
  correct colour category. Analyze clean + full suite green.

> After Phase G, the only trial-time step is flipping the Simulator switch OFF
> with real credentials to let the physical board drive the exact same UI.

---

## 9. Phase H — Scolia integration for all remaining games

Each game gets its own `submitScoliaTurn(TurnResult)` implementation and a
corresponding swap of its input slot in the view (identical pattern to the
two existing pilots: `scoliaInputActive(context) ? ScoliaDartboard(...) :
Numpad(...)`). Numpad paths are **never touched**. Tests must prove the Scolia
path produces identical controller state to the equivalent numpad input.

Each task below is one self-contained unit: implement + view-wire + test +
commit after manual in-app verification. Order is roughly complexity ascending.

---

### H1 — Cricket

**Translation:** Each Scolia dart that hits a cricket number (15–20 or 25/bull)
calls `pressNumpadButton(number)` once, twice, or three times according to the
ring multiplier (single→1, double→2, triple→3). After all 3 darts processed,
call `pressNumpadButton(0)` to end the round. Darts hitting non-cricket numbers
are ignored. The existing `_canAddHit` guard in the controller handles
over-hitting (max 3 hits per number, max 3 darts per round).

**View:** `view_cricket.dart` — swap numpad (cricketMode:true) for
`ScoliaDartboard`.

---

### H2 — Kill Bull

**Translation:** Count bull hits in the turn. Inner bull (50/DB) = **2 bulls**,
outer bull (25/SB) = **1 bull**. Max 6 per round (3×DB). Submit that total via
`pressNumpadButton(total)`.

**View:** `view_killbull.dart`.

---

### H3 — Speed Bull

**Translation:** Same count logic as Kill Bull (inner=2, outer=1). Additionally:
first `THROW_DETECTED` event in Scolia mode **auto-starts** the game (call the
start logic) if `!gameStarted`. Respect `gameEnded`/`lastThrowAllowed` gating.

**View:** `view_speedbull.dart`. The START button remains visible but is
optional — the first dart starts the game automatically.

---

### H4 — Big Ts

**Targets (rotating):** round 1→T20, round 2→T19, round 3→T18, round 4→T20,
... i.e. target triple segment = `[20, 19, 18][currentRound % 3]`. Only triples
of that number count as a hit; everything else is a miss.

**Translation:** Count darts where `ring==triple && segment==targetSegment`,
submit 0–3 via `pressNumpadButton(count)`.

**View:** `view_bigts.dart`.

---

### H5 — Shoot X (99×20)

**Target:** param `x` (always 20 in the menu). Ring multiplier matters: a
single-20 = 1 hit, D20 = 2 hits, T20 = 3 hits. Sum across 3 darts (max 9,
typically 0–6 for standard throws). Submit total via `pressNumpadButton(total)`.

**View:** `view_shootx.dart`.

---

### H6 — Round the Clock Single (RTCS)

**Target:** `currentNumber` (sequential 1→20). Each dart that hits `currentNumber`
in **any ring (single, double, or triple)** counts as... wait — confirmed
clarification: **only singles count** in RTCS. D1 or T1 is a miss. Each dart
hitting S(currentNumber) advances the counter by 1. Max 3 per round. Submit count.

**Note:** RTCX uses `selectedMode`. For RTCS (params `max:10`, no
`needsModeSelection`) the mode is always Single.

**Translation:** Count darts where `ring==single && segment==currentNumber`
(both S and s qualify — same score). Submit 0–3 via `pressNumpadButton(count)`.

**View:** `view_rtcx.dart`.

---

### H7 — Round the Clock D/T (RTCDT)

**Target:** `currentNumber`. Mode: Double or Triple (selected in dialog).
Only the exact required ring on `currentNumber` counts. One advance per qualifying
dart. Submit 0–3.

**Translation:** for Double mode, count darts where `isDoubleOf(currentNumber)`;
for Triple mode, count darts where `ring==triple && segment==currentNumber`.

**Note:** `selectedMode` is set by the in-app mode-selection dialog; the Scolia
adapter reads it from the controller.

**View:** same `view_rtcx.dart` as H6.

---

### H8 — Plan Hit

**Target:** `targets[currentRound]` = a "a-b-c" string of 3 numbers (e.g.
`"4-15-5"`). Order matters: dart 1 must hit target[0], dart 2 must hit target[1],
dart 3 must hit target[2]. A miss means that position is skipped — the player
moves on regardless. **Only singles** count (any single ring, S or s). A double
or triple of the required number is a miss.

**Translation:** For each dart `i` (0,1,2), check if `ring==single &&
segment==int.parse(targets[currentRound].split('-')[i])`. Count successes (0–3).
Submit via `pressNumpadButton(count)`.

**View:** `view_planhit.dart`.

---

### H9 — Double Path

**Targets:** fixed sequences `['16-8-4','20-10-5','4-2-1','12-6-3','18-9-B']`.
Order matters (same in-order rule as Plan Hit). **Only doubles** of each required
number count; singles/triples of that number are a miss. Last round: 'B' = inner
bull (double bull / DB).

**Translation:** For dart `i`, check `isDoubleOf(target[i])` where the last
round's bull target maps to `isDoubleOf(25)` (inner bull). Count 0–3. Submit via
`pressNumpadButton(count)`.

**View:** `view_doublepath.dart`.

---

### H10 — Across Board

**Target:** `targetSequence[currentTargetIndex]` encodes exact ring+segment
(D=double, T=triple, SS=inner-single/s, BS=outer-single/S, SB=outer-bull/25,
DB=inner-bull/Bull). In Scolia mode we have the exact ring, so we can test the
precise match per dart against the sequence. Count how many darts match the
next available targets in order, submit 0–3.

**Translation:** Walk through the 3 darts and the remaining sequence; for each
dart check if it matches the next required target segment (using Scolia's ring
info). Count advances. Submit via `pressNumpadButton(count)`.

**View:** `view_acrossboard.dart`.

---

### H11 — Half It

**Target label:** `labels[round-1]` ∈ `['15','16','D','17','18','T','19','20','B']`.
Scoring rule per label:
- Number label ('15'..'20'): sum of dart values only for darts hitting that
  segment number (any ring, so T20 in a '20' round = 60).
- 'D': sum of double-ring dart values (any number).
- 'T': sum of triple-ring dart values (any number).
- 'B': sum of bull values (25 for outer, 50 for inner).
Submit the total score via the existing digit-entry enter path (set `input` and
call `pressNumpadButton(-1)`, same as xxxcheckout category 1). Score 0 triggers
halving.

**View:** `view_halfit.dart`.

---

### H12 — 10 Up 1 Down (UpDown)

**Success condition:** player must **finish** `currentTarget` in one round
(exactly reach 0 from `currentTarget` using up to 3 darts, finishing on a
double). I.e. the 3 darts must sum exactly to `currentTarget` and the last
scoring dart must be a double or bull.

**Translation:** check if `turn.total == currentTarget` and the last non-zero
dart is a double or bull. Submit `pressNumpadButton(1)` on success, `pressNumpadButton(0)`
on failure.

**View:** `view_updown.dart`.

---

### H13 — 2 Darts

**Targets:** 61–70 (`currentTargetIndex` + 61). Must finish in **exactly 2 darts**
ending on a double/bull.

**Translation:** Check if exactly 2 darts were thrown this turn, they sum to the
target, and the 2nd dart is a double or bull. Submit `pressNumpadButton(1)` on
success, `pressNumpadButton(0)` on failure.

**View:** `view_twodarts.dart`.

---

### H14 — Catch 40

**Targets:** 61–100. Each "round" may span multiple 3-dart turns until the
checkout succeeds (up to 6 darts / 2 turns) or the player gives up.

**Approach (confirmed):** The `ScoliaDartboard` widget accumulates darts across
turns for this game (a "multi-turn mini-leg"). The controller expects **total
darts used** (2–6), not rounds: 2-dart finish = 3 pts, 3-dart = 2 pts, 4–6 = 1 pt,
0 = failed. When the running total from turn start reaches exactly `target`
ending on a double, auto-submit the dart count. If after 6 accumulated darts
(2 takeouts) the target wasn't reached, auto-submit 0 (miss). Note: button 1 is
disabled in the controller (can't finish in 1 dart) — this is correct, never
submit 1. The per-round dart accumulator lives in the widget's state for this
game (a configurable `maxDartsPerRound` extended collector or a simple counter).

**Translation:** Accumulate across turns; on checkout: `pressNumpadButton(dartsUsed)`;
on 6-dart exhaustion: `pressNumpadButton(0)`.

**View:** `view_catchxx.dart`.

---

### H15 — Check 121

**Targets:** starts at 121, increments on success. Up to 3 rounds (each 3 darts)
per attempt. The controller expects **rounds used** (1–3), not darts. Safepoint
fires on `rounds == 1` (finished within the first round, i.e. ≤3 darts).

**Translation:** Accumulate darts across turns (up to 3 turns = 9 darts). When
the running total reaches exactly `currentTarget` ending on a double/bull:
`pressNumpadButton(roundsUsed)` where `roundsUsed = ceil(dartsUsed / 3)`.
If 3 turns exhausted without finishing: `pressNumpadButton(0)` (miss).

**Note:** Catch 40 uses total *darts* (2–6); Check 121 uses total *rounds* (1–3).
This is an existing inconsistency kept intentionally to preserve current game
behaviour. Scolia adapters for both games must convert accordingly.

---

### H16 — Credit Finish

**Phase-aware, two-step per round:**
1. **Score phase** (`GamePhase.scoreInput`): sum the 3 darts → submit total via
   enter path (same as xxxcheckout), respecting the existing validation and the
   predefined score buttons (just use the numeric total directly).
2. **Finish phase** (`GamePhase.finishInput`): the player now attempts to check
   out the accumulated score. Scolia detects the finish: check if `turn.total ==
   remainingScore` ending on double/bull → `pressNumpadButton(1)` (success), else
   `pressNumpadButton(0)` (miss). Phases auto-advance as today.

**View:** `view_creditfinish.dart`.

---

### H17 — Challenge (composite)

**Translation:** No direct translation needed. The `ScoliaDartboard`'s
`controller` field (set in the view) must be the **active sub-controller**
(`currentController` of `ControllerChallenge`). The view wires `onUndoRound` and
`submitScoliaTurn` to delegate to the current sub-controller. Stage advancement
is automatic via the existing `onGameCompleted` callback chain — when a sub-game
ends, the challenge controller swaps `currentController`; the view must rebuild
and update `ScoliaDartboard.controller`.

**View:** `view_challenge.dart`.

---

### Implementation rules (all H tasks)

1. **Never touch the numpad path.** Only add `submitScoliaTurn` to the
   controller and a conditional in the view's input slot.
2. **Tests must prove equivalence:** for each game, a Scolia turn that maps to
   a known numpad input must produce identical controller state.
3. **STOP AND TEST before committing.** After implementing each H task, stop
   and let the user manually test the game in Scolia mode on the device.
   Only commit after the user confirms the game works correctly.
   Fix any issues found during testing before moving to the next game.
4. **One commit per game.** Each H task results in exactly one commit,
   made only after the user has tested and confirmed.
5. **Update this doc's checkboxes** when each task is committed.

### Task checklist

- [x] H1 Cricket
- [x] H2 Kill Bull
- [ ] H3 Speed Bull
- [ ] H4 Big Ts
- [ ] H5 Shoot X
- [ ] H6 RTC Single
- [ ] H7 RTC D/T
- [ ] H8 Plan Hit
- [ ] H9 Double Path
- [ ] H10 Across Board
- [ ] H11 Half It
- [ ] H12 10 Up 1 Down
- [ ] H13 2 Darts
- [ ] H14 Catch 40
- [ ] H15 Check 121
- [ ] H16 Credit Finish
- [ ] H17 Challenge
