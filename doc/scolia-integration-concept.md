# Scolia Home 2 API Integration - Conceptual Design

## Overview

This document captures the conceptual design for adding **Scolia Home 2** as a
second, global input mode to the DART training app. Today, all games are driven
by a virtual numpad on the right-hand side of the screen. The goal is to allow
the app to be driven instead by **automatic dart detection** from a Scolia Home 2
autoscoring system, without replacing the numpad and without rewriting the
existing game logic.

**Status**: Conceptual / pre-implementation.
**Trigger**: A paid Scolia API subscription is required, but a **30-day trial**
is available. The design is intentionally structured so that the entire input
pipeline can be built and tested against a **mock/simulated event source**,
independent of live API access, so the trial month can be spent validating the
real wire format rather than building plumbing.

---

## 1. Feasibility Findings (Scolia API)

Confirmed from Scolia's official pages (`scoliadarts.com/api/`) and the Scolia
Social user manual:

- **Commercial API.** The API is a business offering. Access is granted per
  account, activated manually by a Scolia representative. Expect a monthly cost;
  a **30-day trial** is available for evaluation.
- **Cloud-based, not local.** The Scolia system communicates through Scolia's
  cloud (`game.scoliadarts.com`). There is **no local endpoint** on the home unit
  to rely on. The integration will connect to a **cloud WebSocket**, authenticated
  with credentials tied to the account/board.
- **Event stream** officially includes exactly what the app needs:
  - **Status changes** of the processing unit (e.g. ready / throw phase / offline)
  - **Takeout started / finished** events (darts being pulled → turn boundary)
  - **Throw events** with score, X-Y coordinates, and 3D inclined angles — i.e.
    **per-dart** detections.

> **Unconfirmed until onboarding:** the exact JSON message schema (message type
> names, field names, auth handshake) is only provided during commercial
> onboarding. The design isolates this unknown behind a single parsing layer
> (`ScoliaService`) so it does not leak into game code. Validating the real
> schema is the primary task for the trial month.

---

## 2. Existing Architecture (What We Build On)

The current app already has a clean input abstraction that makes this integration
additive rather than invasive.

- Every game controller implements `NumpadController`:
  ```dart
  abstract class NumpadController {
    void pressNumpadButton(int value);
    String getInput();
    void correctDarts(int value);
    bool isButtonDisabled(int value) => false;
  }
  ```
- The `Numpad` widget is a **pure view**: it only calls
  `controller.pressNumpadButton(value)`. All game state and rules live in the
  controllers. The numpad has no game knowledge.
- There is already precedent for a second input interface
  (`DartboardController.pressDartboard(String)`), confirming alternative inputs
  were anticipated.

### The critical nuance: `pressNumpadButton(value)` does NOT mean the same thing across games

Reading the controllers shows **three distinct semantic categories** for the
input value. This is the single most important fact driving the design.

| Category | Example games | What `value` means | Numpad shown |
|----------|---------------|--------------------|--------------|
| **1. Score-value** | `xxxcheckout` (x01) | An actual dartboard score total for the turn, e.g. `140` | Full 0–9 + presets |
| **2. Direct hit-count** | `shootx`, `planhit` | *How many of the (up to) 3 darts satisfied the goal* (0–3), e.g. "how many hit target X" | Reduced (0–3) |
| **3. Interpreted hit-count** | `bobs27` | *How many darts hit the current, game-defined target* (0–3), which the controller then converts to a score via `_calculateScore(target, hits)` (bull rules etc.) | Reduced (0–3) |

**Implication:** Scolia only ever delivers **raw darts** (segment + ring + value +
coordinates). It does *not* deliver the count-of-successes that categories 2 and 3
require. That count only exists after evaluating each raw dart against the
**game's current goal** (e.g. "was this the required number?", bull = 25 counts as
1 / double-bull = 50 counts as 2). That evaluation is game-specific knowledge that
already lives inside each controller.

Therefore a single generic "sum three darts into a total" layer is **sufficient
only for category 1** and **insufficient for categories 2 and 3**.

---

## 3. Design Decision: Translate, Don't Fork

Two options were considered:

- **(A) Per-game translation** — one shared controller per game, with a small
  Scolia entry point that interprets raw darts against the game's current goal and
  then drives the *same* internal state mutation the numpad path uses.
- **(B) Separate controllers / controller modes** that consume different inputs.

**Chosen: (A) Translate, don't fork.**

Rationale:
- The goal/target state (`x`, `currentTargetIndex`, `targets` sequences, etc.)
  lives inside each controller. A separate Scolia controller would have to
  duplicate all goal-tracking, stats, and undo logic — large and error-prone to
  keep in sync across ~19 games.
- The per-game translation is genuinely small (evaluate darts against the current
  goal → a value the controller already handles). The shared game/stats/undo logic
  is large. Keep the large part shared; localize only the small translation.
- Both input paths converge on the **same internal state mutation**, guaranteeing
  numpad mode and Scolia mode stay consistent, and existing tests keep covering the
  core logic.

**When a separate mode is justified:** only when the Scolia *experience* should
genuinely differ (e.g. auto-advancing targets the instant 3 darts land, or a live
per-dart breakdown). Even then, prefer keeping one controller and exposing an
additional Scolia-specific view rather than forking the controller.

---

## 4. Target Architecture

Layered so that all Scolia/wire-format knowledge stays at the top and all game
meaning stays in the controllers (unchanged core logic):

```
ScoliaService          → owns the cloud WebSocket, auth, heartbeat/reconnect.
                         Parses raw JSON into typed events. Exposes streams:
                           Stream<ScoliaThrow>  throws
                           Stream<ScoliaState>  stateChanges
      ↓
ScoliaTurnCollector    → groups raw darts into a single turn. Closes a turn on
                         takeout event / 3 darts / bust (relies primarily on
                         Scolia's takeout events, not just counting to 3, to
                         handle checkouts and busts with fewer than 3 darts).
      ↓
ScoliaInputAdapter     → subscribes to completed turns and hands the raw darts of
                         the active game to that game's controller.
      ↓
controller.submitScoliaTurn(darts)   ← per-game interpretation; reuses existing
                                        state mutation. NEW method (see §5).
```

- The **generic layers** (`ScoliaService`, `ScoliaTurnCollector`,
  `ScoliaInputAdapter`) know only about "raw darts" and "turn boundaries".
- All **game meaning** stays in the controllers, where it already is.
- The numpad continues to call `pressNumpadButton` exactly as today. Both paths
  end at the same internal state changes.

### Typed models (owned by `ScoliaService`)

```dart
class ScoliaThrow {
  final int segment;   // 1..20, or 25 for bull
  final int ring;      // single / double / triple (and inner/outer bull)
  final int value;     // resolved score for this dart (e.g. T20 = 60)
  // plus optional coordinates / angles if we want heatmaps later
}

enum ScoliaState { ready, throwPhase, takeoutStarted, takeoutFinished, offline }
```

> Exact field names/enums will be finalized against the real schema during the
> trial. Only this file and `ScoliaService` should change when that happens.

---

## 5. Controller Integration Point

Add **one** input-source-agnostic method via a new interface, implemented only by
controllers that support Scolia:

```dart
abstract class ScoliaInputController {
  /// Raw darts from Scolia for one completed turn.
  /// The controller interprets them according to its own game semantics
  /// and mutates state exactly as the equivalent numpad press(es) would.
  void submitScoliaTurn(List<ScoliaThrow> darts);
}
```

Per-category implementation sketch:

- **Category 1 — `xxxcheckout`:** sum `darts` → run the same code path as
  entering that total and pressing enter. (This is the "sum to a total" idea from
  earlier discussion — now just the category-1 special case, not the universal
  mechanism.)
- **Category 2 — `shootx`:** count darts whose segment matches target `x` → that
  count is the 0–3 value the controller already handles.
- **Category 3 — `bobs27`:** count darts hitting `currentTarget` applying the bull
  rule → feed the existing `hits` path.

> **Deliberately avoided:** synthesizing/faking numpad keystrokes from Scolia
> events. The x01 input validators reject certain intermediate digit sequences,
> which would make keystroke replay fragile. A dedicated higher-level method is
> cleaner and safer.

---

## 6. UI / Mode Switch

- A single **global, app-level setting** toggles input mode: **Numpad ↔ Scolia**.
  Numpad remains the default.
- In Scolia mode, the right-hand pane shows a **live "detected darts" panel** in
  place of (or alongside) the numpad.
- **Keep the numpad reachable as manual correction** even in Scolia mode.
  Autoscoring boards misdetect (bounce-outs, wrong ring) often enough that a
  training experience without manual override is frustrating. The existing
  `correctDarts` and undo (`-2`) handling already provide the correction
  primitives.
- Games not yet adapted simply do not offer Scolia mode (graceful degradation).

---

## 7. Open Semantic Questions (to pin down before/while implementing)

These affect how the per-game interpreter counts hits:

1. **`planhit` sequence rule.** Targets are a 3-number sequence (e.g. `"5-12-3"`).
   Does each of the 3 darts have to hit its corresponding number in order, or does
   hitting any of the three count? The controller currently only stores a manually
   entered 0–3 count, so this rule is not yet encoded in code.
2. **Bull counting rule.** The stated rule is 25 = 1 bull, 50 (double-bull) = 2.
   Confirm whether "double-bull counts as two" is global or specific to certain
   games. It changes how the interpreter tallies bull hits.
3. **Turn-boundary source.** Confirm which Scolia event most reliably closes a turn
   (takeout-started vs. takeout-finished) and how busts / early checkouts (fewer
   than 3 darts) are represented.

---

## 8. Risks & Tradeoffs

- **Schema unconfirmed** until onboarding — mitigated by isolating parsing in
  `ScoliaService`; the trial month validates it. Everything above the parser is
  insulated.
- **Turn closing** (3 darts vs. takeout vs. bust/checkout with <3 darts) is the
  trickiest generic bit; rely on Scolia's takeout events, not just a dart count.
- **Cloud dependency & latency** — offline means no Scolia mode; numpad fallback
  covers this.
- **Misdetection** — always keep numpad correction available in Scolia mode.
- **Web target** — the app already builds for web; browser WebSocket + Scolia's
  cloud model fit naturally. Native platforms also supported.
- **Not all games map cleanly** — start with the games whose mapping is simplest
  and validate end-to-end before broad rollout.

---

## 9. Recommended Implementation Sequence

Designed so most work is doable and testable **during the trial**, and much of it
even before live API access using a mock event source.

1. **(External gate)** Obtain API access via the trial; capture the real message
   schema and auth details. Update the models in §4 / `ScoliaService` accordingly.
2. **Build the pipeline against a mock source (no live API needed):**
   - `ScoliaThrow` / `ScoliaState` models.
   - `ScoliaService` with a **mock/simulated event source** so throws can be
     injected in tests.
   - `ScoliaTurnCollector` + `ScoliaInputAdapter`.
3. **Pilot on two controllers** to prove "translate, don't fork" on the hardest
   case:
   - one **score-value** game (`xxxcheckout`), and
   - one **interpreted hit-count** game (`bobs27`),
   each implementing `submitScoliaTurn`.
   - **Unit tests must prove the Scolia path and the numpad path produce identical
     controller state** for equivalent throws.
4. **Add the global mode toggle** + live detected-darts panel, keeping numpad
   correction available.
5. **Roll out** `submitScoliaTurn` to the remaining games, category by category.

---

## 10. Summary

- The app's `NumpadController` abstraction is the correct integration seam.
- Scolia is **cloud WebSocket**, **per-dart**, **paid (30-day trial)**.
- Input value semantics differ across games (score vs. hit-count vs. interpreted
  hit-count), so a universal "sum to total" layer is not enough.
- **Chosen approach:** one shared controller per game + a small per-game
  `submitScoliaTurn(darts)` that interprets raw Scolia darts against the game's
  current goal and reuses the existing state mutation.
- Fully additive: numpad stays the default and remains available as correction.
- Wire-format uncertainty is isolated in `ScoliaService`; the whole pipeline can
  be built and unit-tested with a mock source before/independent of live access.
