# DART Training App - Developer Documentation

## Overview

The DART Training App is a Flutter-based mobile application designed for dart training and skill improvement. The app provides various training games that help players practice different aspects of dart throwing, from basic scoring to advanced finishing techniques.

**Full App Name**: DART - Damit Alex Richtig Trainiert  
**Platform**: Flutter (Android/iOS)  
**Architecture**: Provider-based State Management with Service-Oriented MVC pattern

## Application Structure

### Directory Organization

```
lib/
├── controller/          # Game logic controllers (16 files)
├── view/               # UI screens for each game (15 files)
├── widget/             # Reusable UI components (9 files)
├── interfaces/         # Abstract interfaces and contracts (3 files)
├── services/           # Business logic services (3 files)
├── utils/              # Utility functions (2 files)
│   ├── responsive.dart # Responsive design utilities
│   └── [other utils]
├── main.dart          # Application entry point
└── styles.dart        # Global styling definitions

test/
├── *_widget_test.dart  # Widget tests for each game (15 files)
├── *.mocks.dart       # Generated mock files (15 files)
└── test coverage: 233 tests across all games (all passing)
```

### Core Components

#### Controllers (`/controller`)
- **Purpose**: Implement game logic, state management, and coordinate with services
- **Pattern**: Provider-based ChangeNotifier with dependency injection support
- **Base Class**: `ControllerBase` - provides common functionality and service access
- **Interfaces**: Implement `MenuitemController` and `NumpadController`
- **Key Features**:
  - Service initialization and management
  - Game state management
  - UI callback handling
  - Statistics integration

**Controller Files:**
- `controller_base.dart` - Abstract base class with common functionality
- `controller_bigts.dart` - Big Ts triple hitting practice
- `controller_bobs27.dart` - Bob's 27 double round the clock
- `controller_catchxx.dart` - Catch 40 finishing practice
- `controller_check121.dart` - Check 121 specific scenario
- `controller_cricket.dart` - Cricket game with target completion tracking
- `controller_doublepath.dart` - Double finishing sequences
- `controller_finishes.dart` - Finish knowledge training with range selection dialog
- `controller_halfit.dart` - Half It accuracy game
- `controller_killbull.dart` - Bull hitting practice
- `controller_rtcx.dart` - Round the Clock variants
- `controller_shootx.dart` - Scoring practice games
- `controller_speedbull.dart` - Timed bull hitting
- `controller_twodarts.dart` - Two-dart finishing
- `controller_updown.dart` - 10 Up 1 Down progression
- `controller_xxxcheckout.dart` - Checkout practice games

#### Views (`/view`)
- **Purpose**: Define UI layouts and user interactions for each game
- **Pattern**: Stateless widgets that consume controller state via Provider
- **Structure**: Consistent layout with header, game area, numpad, and stats
- **Initialization**: Route-based controller initialization with test compatibility

**View Files:**
- `view_bigts.dart` - Big Ts UI
- `view_bobs27.dart` - Bob's 27 UI
- `view_catchxx.dart` - Catch XX UI
- `view_check121.dart` - Check 121 UI
- `view_cricket.dart` - Cricket UI
- `view_doublepath.dart` - Double Path UI
- `view_finishes.dart` - Finishes UI
- `view_halfit.dart` - Half It UI
- `view_killbull.dart` - Kill Bull UI
- `view_rtcx.dart` - Round the Clock UI
- `view_shootx.dart` - Shoot X UI
- `view_speedbull.dart` - Speed Bull UI
- `view_twodarts.dart` - Two Darts UI
- `view_updown.dart` - Up Down UI
- `view_xxxcheckout.dart` - XXX Checkout UI

#### Services (`/services`)
- **Purpose**: Encapsulate business logic and data operations
- **Pattern**: Service-oriented architecture with dependency injection
- **Key Services**:
  - `StatsService` - Statistics calculation and management
  - `StorageService` - Data persistence and retrieval
  - `SummaryService` - Game summary and dialog management

#### Widgets (`/widget`)
- **Purpose**: Reusable UI components shared across games
- **Key Components**:
  - `Menu` - Main game selection grid (4x5 layout)
  - `Numpad` - Configurable input pad with dynamic buttons
  - `Header` - Game title and navigation
  - `ScoreColumn` - Table display component
  - `SummaryDialog` - End-game results
  - `FinishesRangeDialog` - Pre-game range selection for Finishes
  - `Checkout` - Checkout suggestion dialog
  - `FullCircle` - Dartboard visualization
  - `ArcSection` - Dartboard segment component
  - `CheckNumber` - Number validation widget

#### Interfaces (`/interfaces`)
- **Purpose**: Define contracts for controllers and components
- **Key Interfaces**:
  - `MenuitemController` - Game initialization contract
  - `NumpadController` - Input handling contract
  - `DartboardController` - Dartboard interaction contract

#### Utils (`/utils`)
- **Purpose**: Utility functions and helpers
- **Components**:
  - `StatsFormatter` - Statistics formatting utilities

## Architectural Patterns

### Service-Oriented Architecture
- **Services Layer**: Business logic separated from controllers
- **Dependency Injection**: Services injected into controllers via base class
- **Separation of Concerns**: Clear boundaries between UI, logic, and data

### State Management
- **Framework**: Provider package
- **Pattern**: ChangeNotifier-based controllers
- **Scope**: Global providers for all game controllers
- **State Flow**: UI → Controller → Service → State Change → UI Update
- **Initialization**: Route-based with MenuItem passing

### MVC Architecture
- **Model**: Data structures within services + GetStorage persistence
- **View**: Flutter widgets in `/view` directory
- **Controller**: Game logic classes in `/controller` directory coordinating with services

### Navigation Architecture
- **Menu System**: MenuItem-based navigation with route arguments
- **Controller Initialization**: Views initialize controllers from route arguments
- **Test Compatibility**: Nullable MenuItem handling for test scenarios

## Game Workflow

### Application Lifecycle

1. **App Initialization**
   - Initialize GetStorage for all games
   - Set landscape orientation
   - Setup Provider tree with all controllers

2. **Menu Navigation**
   - Display 4x5 grid of available games (20 total games)
   - Each game represented by `MenuItem` with controller and view
   - Navigation passes MenuItem through route arguments
   - Dynamic layout calculation based on screen size

3. **Game Execution**
   - Controller initialization via route arguments and `init(MenuItem)`
   - Service initialization (StatsService, StorageService)
   - View rendering with real-time state updates
   - User input handling through numpad interface
   - Continuous state persistence to local storage

4. **Game Completion**
   - Summary dialog with game results via SummaryService
   - Statistics update and persistence via StatsService
   - Return to main menu

### Data Flow

```
User Input → Numpad → Controller.pressNumpadButton() → 
Service Operations → State Update → notifyListeners() → 
View Rebuild → UI Update
```

### Controller Initialization Flow

```
Menu Navigation → Route with MenuItem → View Build → 
Controller from Provider → Initialize with MenuItem → 
Services Setup → Game Ready
```

### Persistence Strategy
- **Technology**: GetStorage (local key-value storage)
- **Service**: StorageService handles all persistence operations
- **Scope**: Per-game storage containers with unique IDs
- **Data**: Game statistics, records, and historical data
- **Timing**: Real-time updates during gameplay

## Game Types and Categories

### Training Games (20 Total Games)
- **Checkout Games**: 170x10 (max 3), 501x5, 501x5 (max 7) - Practice finishing combinations
- **Accuracy Games**: Round the Clock Single/Double/Triple - Precision training
- **Finish Training**: FinishQuest (with range selection dialog) - Learn finishing routes for ranges 61-80, 81-107, 108-135, 136-170
- **Specialty Games**: Kill Bull, Speed Bull, Big Ts (triple hitting practice) - Specific skill focus

### Skill Development Games
- **Double Path**: Practice common double finishing sequences
- **10 Up 1 Down**: Progressive target challenge
- **2 Darts**: Two-dart finishing practice with Double Bull
- **Check 121**: Specific checkout scenario training with save points

### Assessment Games
- **Bob's 27**: Double round the clock challenge
- **Half It**: Accuracy under pressure
- **Catch 40**: Finishing from various scores (61-100)
- **99 x 20**: Scoring practice on 20 segment
- **Big Ts**: Triple hitting assessment and practice

## Technical Implementation Details

### Controller Architecture
- **Provider Pattern**: Each controller extends ChangeNotifier
- **Service Integration**: Controllers use services for business logic
- **State Variables**: Game-specific data (scores, rounds, targets)
- **Initialization**: Route-based with MenuItem parameter
- **Dialog Callbacks**: UI interaction callbacks for decoupling from BuildContext
- **Methods**: 
  - `init(MenuItem)` - Game setup and service initialization
  - `pressNumpadButton()` - Input processing
  - `getStats()` - Statistics formatting via StatsService
  - Display methods for UI data formatting

### Range Selection Dialog Pattern
The Finishes game implements a pre-game range selection dialog to consolidate multiple game variants into a single menu item:

**Implementation Pattern:**
1. **Controller State**: Controller starts with `from=0, to=0` indicating range selection needed
   ```dart
   bool get needsRangeSelection => from == 0 && to == 0;
   void setRange(int fromRange, int toRange) { /* initialize game */ }
   ```

2. **View Integration**: View shows dialog when range selection is needed
   ```dart
   if (controller.needsRangeSelection && !_dialogShown) {
     _dialogShown = true;
     WidgetsBinding.instance.addPostFrameCallback((_) {
       _showRangeSelectionDialog(context, controller);
     });
   }
   ```

3. **Dialog Component**: `FinishesRangeDialog` provides 4 predefined ranges
   - Uses SummaryDialog styling for consistency
   - IntrinsicWidth for proper sizing
   - Custom radio button implementation to avoid deprecation warnings

4. **Dynamic Title**: Game title updates based on selected range
   ```dart
   String getGameTitle() {
     if (needsRangeSelection) return 'Finishes wissen';
     return 'Finishes wissen $from-$to';
   }
   ```

**Used in**: FinishQuest game for range selection (61-80, 81-107, 108-135, 136-170)
Some games implement a two-dialog workflow where an intermediate dialog is shown before the final summary dialog:

**Implementation Pattern:**
1. **Controller Callbacks**: Controllers define callback functions for UI interactions
   ```dart
   VoidCallback? onGameEnded;
   Function(int remaining, int score)? onShowCheckout;
   VoidCallback? onCheckoutClosed;
   ```

2. **View Setup**: Views set up callback handlers during build
   ```dart
   controller.onShowCheckout = (remaining, score) {
     // Show first dialog
     showDialog(context: context, builder: (context) => FirstDialog(...));
   };
   controller.onCheckoutClosed = () {
     // Handle first dialog closure, trigger second dialog
     controller.handleCheckoutClosed();
   };
   ```

3. **Controller Flow**: Controllers trigger dialogs in sequence
   ```dart
   // Trigger first dialog
   onShowCheckout?.call(remaining, score);
   
   // Handle first dialog closure
   void handleCheckoutClosed() {
     WidgetsBinding.instance.addPostFrameCallback((_) {
       triggerGameEnd(); // This triggers onGameEnded callback
     });
   }
   ```

**Used in**: XXXCheckout (checkout → summary), RTCX (dart count → summary)

### Service Architecture
- **StatsService**: Handles all statistics calculations and formatting
- **StorageService**: Manages GetStorage operations with game-specific containers
- **SummaryService**: Creates and displays game summary dialogs
- **Dependency Injection**: Services injected into controllers via ControllerBase

### UI Components
- **Responsive Design**: Dynamic layout calculation for landscape orientation
- **Consistent Styling**: Centralized style definitions in `styles.dart`
- **Configurable Numpad**: Flexible input interface with boolean configuration
- **Table Display**: Scrollable game progress tables via ScoreColumn
- **Route-Based Navigation**: MenuItem passed through route arguments

### Data Persistence
- **Local Storage**: GetStorage for offline capability
- **Service Layer**: StorageService encapsulates all storage operations
- **Statistics Tracking**: Comprehensive performance metrics via StatsService
- **Record Keeping**: Personal bests and achievements
- **Data Structure**: Key-value pairs per game type with unique game IDs

### Testing Architecture
- **Comprehensive Coverage**: 118 tests across all games
- **Mock Generation**: Mockito-generated mocks for dependencies
- **Widget Testing**: Full widget tests for each game
- **Test Compatibility**: Views handle null MenuItem for test scenarios
- **Dependency Injection**: Test-friendly controller constructors

## Development Patterns

### Adding New Games

1. **Create Controller**
   - Extend `ControllerBase`
   - Implement required interfaces (`MenuitemController`, `NumpadController`)
   - Define game-specific logic and state
   - Use services for business logic and persistence

2. **Create View**
   - Implement consistent layout structure
   - Handle MenuItem from route arguments
   - Configure numpad for game requirements
   - Setup statistics display

3. **Create Tests**
   - Widget tests with mock dependencies
   - Generate mocks with build_runner
   - Test all game scenarios and edge cases

4. **Integration**
   - Add controller to Provider tree in `main.dart`
   - Create MenuItem in `menu.dart`
   - Import necessary dependencies

### Service Integration
- **Use ControllerBase**: Inherit service access methods
- **Initialize Services**: Call `initializeServices()` in controller `init()`
- **Service Methods**: Use `statsService`, `storageService` properties
- **Error Handling**: Services throw StateError if not initialized

### Styling and Theming
- **Global Styles**: Defined in `styles.dart`
- **Color Scheme**: Dark theme with accent colors
- **Typography**: Consistent font sizes and weights
- **Component Styling**: Reusable style definitions

### Input Handling
- **Numpad Configuration**: Boolean flags for button visibility
- **Input Validation**: Controller-level input processing
- **Undo Functionality**: State rollback capabilities
- **Button States**: Dynamic enable/disable logic

## Performance Considerations

### State Management
- **Efficient Updates**: Targeted notifyListeners() calls
- **Service Layer**: Business logic separated from UI concerns
- **Memory Management**: Provider-based lifecycle management
- **UI Rebuilds**: Provider-based selective updates

### Data Storage
- **Service Abstraction**: StorageService handles all persistence
- **Local Persistence**: Fast GetStorage operations
- **Minimal Data**: Efficient storage structure
- **Batch Operations**: Grouped storage updates

### UI Rendering
- **Landscape Orientation**: Optimized for tablet/phone landscape
- **Dynamic Layouts**: Responsive design patterns
- **Efficient Widgets**: Stateless widgets where possible
- **Route-Based Navigation**: Efficient navigation with arguments

## Testing Strategy

### Test Coverage
- **233 Total Tests**: Comprehensive coverage across all games
- **Widget Tests**: Full UI and interaction testing
- **Mock Dependencies**: Isolated testing with Mockito
- **Edge Cases**: Comprehensive scenario coverage

### Test Architecture
- **Mock Generation**: Automated with build_runner and Mockito
- **Dependency Injection**: Test-friendly controller constructors
- **Service Mocking**: Mock services for isolated testing
- **Route Compatibility**: Tests work without MenuItem initialization

### Running Tests
```bash
# Run all tests
flutter test

# Run specific game tests
flutter test test/cricket_widget_test.dart

# Generate mocks
flutter packages pub run build_runner build
```

## Future Extensibility

### Adding Games
- **Modular Design**: Easy addition of new game types
- **Consistent Patterns**: Established development workflow
- **Service Integration**: Reusable business logic services
- **Flexible Components**: Reusable UI elements

### Feature Enhancement
- **Statistics System**: Expandable metrics tracking via StatsService
- **UI Components**: Modular widget architecture
- **Data Export**: Extensible storage system via StorageService
- **Service Extension**: Easy addition of new services

### Platform Support
- **Cross-Platform**: Flutter's native capabilities
- **Responsive Design**: Adaptable to different screen sizes
- **Offline Capability**: Local storage independence

## Dependencies

### Core Dependencies
- **flutter**: UI framework
- **provider**: State management (^6.1.2)
- **get_storage**: Local data persistence (^2.1.1)
- **tuple**: Data structure utilities (^2.0.2)
- **collection**: Collection utilities (^1.18.0)
- **path_provider**: File system access (^2.1.2)
- **duration_button**: UI component (^1.0.0)

### Development Tools
- **flutter_lints**: Code quality (^6.0.0)
- **mockito**: Testing mocks (^5.4.4)
- **build_runner**: Code generation (^2.4.9)
- **hrk_flutter_test_batteries**: Test utilities (^1.2.0)
- **test**: Testing framework (^1.25.15)

## Build and Deployment

### Development
- **Environment**: Flutter SDK
- **IDE**: Any Flutter-supported IDE
- **Code Quality**: `flutter analyze` (0 issues)
- **Testing**: `flutter test` (233 tests passing)

### Production
- **Platforms**: Android APK/iOS IPA
- **Orientation**: Landscape mode only
- **Storage**: Local device storage only
- **Build**: `flutter build apk` or `flutter build ios`

## Responsive Design Implementation

### Overview
The app implements responsive design to ensure usability across different screen sizes, from tablets to phones, while maintaining the original tablet-optimized experience.

### Core Components

#### ResponsiveUtils (`lib/utils/responsive.dart`)
- **Purpose**: Centralized responsive scaling calculations
- **Key Functions**:
  - `getTextScaleFactor(context)`: Base scaling factor based on screen dimensions
  - `isPhoneSize(context)`: Device type detection (< 600px = phone)
  - Element-specific scaling functions for different UI components
  - `getButtonMargin(context)`: Responsive spacing for UI elements

#### Text Scaling Strategy
- **Base Calculation**: Scale factor = screen dimension / 800px (tablet baseline)
- **Aggressive Phone Scaling**: Additional reduction for screens < 600px
- **Element-Specific Scaling**: Different scale factors for different UI components
- **Context-Dependent Styles**: All text styles converted from const to functions

#### Key Responsive Features
- **Menu Buttons**: Single-line text on phones (newlines → spaces), larger text
- **Numpad**: Reduced margins (10px → 3px) for more usable space
- **Table Text**: Optimized scaling to fit content while remaining readable
- **Icons**: Responsive sizing for better visibility (e.g., back arrow)
- **Button Sizes**: Preserved for touch interaction, only text scales
- **Dartboard**: Responsive radius bounds (120-180px on phones vs 200-280px on tablets)

### Implementation Pattern
```dart
// Text styles use context for responsive scaling
TextStyle exampleTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 42),
    // ... other properties
  );
}

// UI elements check screen size for adaptive behavior
Widget build(BuildContext context) {
  final isPhone = ResponsiveUtils.isPhoneSize(context);
  final margin = ResponsiveUtils.getButtonMargin(context);
  // ... adaptive UI logic
}
```
