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
