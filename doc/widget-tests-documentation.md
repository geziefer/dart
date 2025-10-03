# Widget Tests Documentation

This document provides an overview of all widget tests in the dart application. The tests focus on game logic validation rather than UI testing, ensuring that each game's business logic functions correctly.

## Technical Overview

### Test Setup and Architecture

All widget tests follow a consistent pattern using Flutter's testing framework with the following key components:

- **Test Framework**: Flutter Test with `testWidgets` for widget-based testing
- **Mocking**: Mockito framework for mocking dependencies, particularly `GetStorage` for persistence
- **Test Structure**: Each game has its own test file with a dedicated test group
- **Mock Generation**: Uses `@GenerateMocks` annotation to generate mock classes automatically
- **Overflow Handling**: Tests use `disableOverflowError()` to prevent UI overflow issues during testing

### Common Setup Pattern

Each test class follows this setup pattern:
- Mock storage is created fresh for each test
- Default mock responses are configured to simulate fresh game statistics
- Controllers are instantiated with dependency injection for testability
- MenuItem objects are created to properly initialize game controllers

### Test Execution

Tests use Flutter's `WidgetTester` to:
- Build widget trees with `MaterialApp` and `Provider` for state management
- Simulate user interactions through button taps and input
- Verify game state changes and business logic
- Validate statistics calculations and storage operations
- Test dialog workflows including sequential dialog patterns (e.g., checkout dialog followed by summary dialog)

## Game Test Classes

### 1. Double Path Game Widget Tests
**Test Class**: `doublepath_widget_test.dart`

**Test Cases**:
- Complete Double Path game workflow - all 5 rounds
- Double Path undo functionality test
- Double Path point calculation verification
- Double Path return button for zero hits
- Double Path input validation
- Double Path statistics with existing data
- Double Path undo edge cases
- Double Path target sequence consistency
- Double Path current stats calculation

**What is tested**: Target sequence generation, point calculation based on hits, round progression through 5 rounds, undo functionality, input validation (0-3 hits), statistics tracking and storage operations.

### 2. Big Ts Game Widget Tests
**Test Class**: `bigts_widget_test.dart`

**Test Cases**:
- Complete Big Ts game workflow - all 10 rounds
- Big Ts undo functionality test
- Big Ts point calculation verification
- Big Ts return button for zero hits
- Big Ts input validation
- Big Ts average calculation
- Big Ts undo edge cases

**What is tested**: Triple hitting practice (T20, T19, T18), point calculation based on hits (0→0, 1→1, 2→3, 3→6 points), round progression through 10 rounds, undo functionality, input validation (0-3 hits), average calculation at different game stages, and statistics tracking.

### 3. Two Darts Game Widget Tests
**Test Class**: `twodarts_widget_test.dart`

**Test Cases**:
- Complete Two Darts game workflow - target progression
- Two Darts undo functionality test
- Two Darts return button for failure
- Two Darts target generation logic
- Two Darts game completion scenarios
- Two Darts statistics with existing data
- Two Darts undo edge cases
- Two Darts invalid input handling
- Two Darts current stats calculation

**What is tested**: Target sequence progression, success/failure tracking, game completion after 10 targets, undo functionality, input validation, and statistics calculation.

### 4. CatchXX Game Widget Tests
**Test Class**: `catchxx_widget_test.dart`

**Test Cases**:
- CatchXX widget creation and initial state
- CatchXX basic scoring functionality
- CatchXX different dart counts scoring
- CatchXX no score scenarios
- CatchXX button 1 disabled
- CatchXX target 99 special case
- CatchXX undo functionality
- CatchXX undo edge cases
- CatchXX statistics calculation
- CatchXX string generation methods
- CatchXX interface methods
- CatchXX game progression
- CatchXX statistics with existing data

**What is tested**: Scoring based on dart count (2-6 darts), special cases for impossible finishes, target 99 special handling, undo functionality, and statistics tracking.

### 5. Speed Bull Game Widget Tests
**Test Class**: `speedbull_widget_test.dart`

**Test Cases**:
- Complete Speed Bull game workflow - timer based
- Speed Bull undo functionality test
- Speed Bull return button for zero hits
- Speed Bull pre-game state handling
- Speed Bull input validation
- Speed Bull statistics with existing data
- Speed Bull undo edge cases
- Speed Bull custom duration test
- Speed Bull current stats calculation

**What is tested**: Timer-based gameplay, hit counting during timed rounds, game duration handling, pre-game state management, and statistics calculation.

### 6. HalfIt Game Widget Tests
**Test Class**: `halfit_widget_test.dart`

**Test Cases**:
- HalfIt widget creation and initial state
- HalfIt labels and targets
- HalfIt basic input building
- HalfIt input validation
- HalfIt input clearing
- HalfIt interface methods
- HalfIt statistics methods
- HalfIt with existing statistics
- HalfIt score submission and progression
- HalfIt half-it logic
- HalfIt undo submitted scores
- HalfIt game completion
- HalfIt summary creation
- HalfIt average score calculation
- Menu widget MenuItem creation and initialization
- Menu widget controller provider logic

**What is tested**: Target sequence (20, 19, 18, 17, 16, 15, Bull, 14, 13), score halving logic when missing targets, input validation, game progression through 9 rounds, and statistics calculation.

### 7. Bobs 27 Game Widget Tests
**Test Class**: `bobs27_widget_test.dart`

**Test Cases**:
- Complete Bobs 27 game workflow - all targets
- Bobs 27 undo functionality test
- Bobs 27 return button for miss
- Bobs 27 score calculation and target progression
- Bobs 27 game ending conditions
- Bobs 27 losing condition - score reaches zero
- Bobs 27 input validation
- Bobs 27 statistics with existing data
- Bobs 27 undo edge cases
- Bobs 27 current stats calculation
- Bobs 27 averaging logic - positive scores only

**What is tested**: Score reduction from 27 points, target progression (1-20, Bull), win/lose conditions, score validation, statistics tracking, and averaging logic that sums only positive scores but divides by total rounds (same behavior as HalfIt game).

### 8. Check 121 Game Widget Tests
**Test Class**: `check121_widget_test.dart`

**Test Cases**:
- Complete Check 121 game workflow - target progression
- Check 121 undo functionality test
- Check 121 return button for miss
- Check 121 target and save point progression
- Check 121 game ending conditions
- Check 121 input validation
- Check 121 statistics with existing data
- Check 121 undo edge cases
- Check 121 highest target tracking
- Check 121 current stats calculation

**What is tested**: Target progression with save points, miss counting (game ends after 10 misses), highest target reached tracking, and statistics calculation.

### 9. Finishes Game Widget Tests
**Test Class**: `finishes_widget_test.dart`

**Test Cases**:
- Finishes widget creation and initial state
- Finishes finish generation
- Finishes text generation methods
- Finishes initial statistics
- Finishes statistics string
- Finishes with existing statistics
- Finishes range validation
- Finishes state enum values
- Finishes data structure validation
- Finishes average calculation

**What is tested**: Range selection dialog integration, random finish generation within user-selected ranges (61-80, 81-107, 108-135, 136-170), finish data structure validation, statistics tracking, text formatting methods, and dynamic title generation based on selected range. Tests verify that the controller properly initializes with `setRange()` method and handles the pre-game range selection workflow.

### 10. RTCX Game Widget Tests
**Test Class**: `rtcx_widget_test.dart`

**Test Cases**:
- Complete RTCX game workflow - number progression
- RTCX undo functionality test
- RTCX return button for no hits
- RTCX input validation and limits
- RTCX game completion logic
- RTCX statistics calculation
- RTCX undo edge cases
- RTCX round limit functionality

**What is tested**: Number progression (1-20), dart counting per round, round limits, input validation, checkout dialog integration for accurate dart counting in final round, and statistics calculation. The game now shows a checkout dialog before the summary to allow players to specify the exact number of darts used in the final round, ensuring accurate dart count statistics.

### 11. 10 Up 1 Down Game Widget Tests
**Test Class**: `updown_widget_test.dart`

**Test Cases**:
- Complete 10 Up 1 Down game workflow - success progression
- 10 Up 1 Down undo functionality test
- 10 Up 1 Down target progression logic
- 10 Up 1 Down return button for failure
- 10 Up 1 Down game completion and statistics
- 10 Up 1 Down statistics with existing data
- 10 Up 1 Down undo edge cases
- 10 Up 1 Down target boundary conditions
- 10 Up 1 Down current stats calculation

**What is tested**: Target adjustment based on success/failure (up on success, down on failure), boundary conditions, game completion after 13 rounds, and statistics tracking.

### 12. Kill Bull Game Widget Tests
**Test Class**: `killbull_widget_test.dart`

**Test Cases**:
- Complete Kill Bull game workflow - basic scenario
- Kill Bull undo functionality test
- Kill Bull with existing game statistics
- Kill Bull return button for zero bulls
- Kill Bull immediate game end
- Kill Bull extended game scenario
- Kill Bull undo edge cases
- Kill Bull score calculation verification

**What is tested**: Bull hit counting, game ending when missing bulls, score calculation, immediate game end scenarios, and statistics tracking.

### 13. ShootX Game Widget Tests
**Test Class**: `shootx_widget_test.dart`

**Test Cases**:
- ShootX widget creation and initial state
- ShootX basic scoring functionality
- ShootX return button functionality
- ShootX undo functionality
- ShootX undo edge cases
- ShootX statistics calculation
- ShootX string generation methods
- ShootX interface methods
- ShootX game progression
- ShootX statistics with existing data

**What is tested**: Hit counting and scoring, return button functionality, undo operations, statistics calculation, and data formatting methods.

### 14. XXXCheckout Game Widget Tests
**Test Class**: `xxxcheckout_widget_test.dart`

**Test Cases**:
- XXXCheckout widget creation and initial state
- XXXCheckout basic input building
- XXXCheckout input validation
- XXXCheckout input clearing
- XXXCheckout interface methods
- XXXCheckout statistics methods
- XXXCheckout score submission
- XXXCheckout bogey number validation
- XXXCheckout checkout detection
- XXXCheckout pre-defined values
- XXXCheckout long press return
- XXXCheckout undo submitted scores
- XXXCheckout dart correction
- XXXCheckout average calculations
- XXXCheckout game end detection
- XXXCheckout summary creation
- XXXCheckout with existing statistics
- XXXCheckout bust prevention

**What is tested**: Checkout game logic, bogey number validation, bust prevention, dart counting, average calculations, leg completion detection, and statistics tracking.

### 15. Checkout Widget Business Logic Tests
**Test Class**: `checkout_widget_test.dart`

**Test Cases**:
- Checkout widget constructor and properties
- Checkout widget constructor with null callback
- Checkout widget build method execution paths
- Checkout widget conditional button rendering
- Checkout widget button press integration
- Checkout widget callback integration
- Checkout widget failed checkout scenario
- Checkout dart calculation comprehensive test
- Checkout dart correction business logic
- Checkout edge cases
- Checkout score validation integration

**What is tested**: Checkout dialog functionality for both score-based checkout games (XXXCheckout) and target-based games (RTCX). Tests cover dual-mode operation with `isCheckoutMode` flag, dart calculation logic for different score ranges, button rendering based on possible dart counts, callback integration, and dart correction functionality. The widget now supports both traditional checkout scenarios and target-count scenarios for accurate final round dart counting.

### 16. Menu Widget Business Logic Tests
**Test Class**: `menu_widget_test.dart`

**Test Cases**:
- Menu games comprehensive data validation
- Menu game type categorization logic
- Menu widget game difficulty progression business logic
- Menu widget comprehensive parameter validation

**What is tested**: Menu widget functionality, navigation logic, controller management, and game categorization. Tests verify the consolidated FinishQuest game structure (single game with ID 'FQ' instead of multiple range-specific games), "Frei" placeholder games pointing to 501x5 checkout, and proper MenuItem validation for all 20 games in the 4x5 grid layout.

### 17. Across Board Game Widget Tests
**Test Class**: `acrossboard_widget_test.dart`

**Test Cases**:
- Across Board game initialization
- Across Board target progression
- Across Board undo functionality
- Across Board input validation
- Across Board game completion
- Across Board summary creation
- Across Board statistics calculation
- Across Board opposite number mapping

**What is tested**: Random start number generation (1-20), target sequence creation with 11 targets (D→BS→T→SS→SB→DB→SB→SS→T→BS→D), opposite number mapping validation using dartboard layout pairs, target progression and hit tracking, undo functionality including zero-hit rounds, input validation with smart button disabling, game completion detection, checkout dialog integration, and comprehensive statistics calculation testing (darts per target average in various scenarios including initial state, progressive hits, and zero-hit rounds).

## Test Coverage Summary

The widget tests provide comprehensive coverage of:
- Game logic validation for all dart games
- Input validation and error handling
- Undo functionality across all games
- Statistics calculation and persistence
- Game state management including range selection dialogs
- Edge cases and boundary conditions
- Controller initialization and dependency injection
- Storage operations and data persistence
- Dialog workflows including pre-game selection dialogs
- Consolidated game structures and placeholder game functionality

Each test ensures that the business logic functions correctly independent of the UI implementation, providing confidence in the core game mechanics, dialog interactions, and data handling. The tests have been updated to handle the new consolidated FinishQuest game with range selection dialog and the "Frei" placeholder games.
