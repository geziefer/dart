# DART Training App - Developer Documentation

## Overview

The DART Training App is a Flutter-based mobile application designed for dart training and skill improvement. The app provides various training games that help players practice different aspects of dart throwing, from basic scoring to advanced finishing techniques.

**Full App Name**: DART - Damit Alex Richtig Trainiert  
**Platform**: Flutter (Android/iOS)  
**Architecture**: Provider-based State Management with MVC pattern

## Application Structure

### Directory Organization

```
lib/
├── controller/          # Game logic controllers
├── view/               # UI screens for each game
├── widget/             # Reusable UI components
├── interfaces/         # Abstract interfaces and contracts
├── main.dart          # Application entry point
└── styles.dart        # Global styling definitions
```

### Core Components

#### Controllers (`/controller`)
- **Purpose**: Implement game logic, state management, and data persistence
- **Pattern**: Singleton pattern with Provider integration
- **Base Class**: `ControllerBase` - provides common functionality
- **Interfaces**: Implement `MenuitemController` and `NumpadController`

#### Views (`/view`)
- **Purpose**: Define UI layouts and user interactions for each game
- **Pattern**: Stateless widgets that consume controller state via Provider
- **Structure**: Consistent layout with header, game area, numpad, and stats

#### Widgets (`/widget`)
- **Purpose**: Reusable UI components shared across games
- **Key Components**:
  - `Menu` - Main game selection grid
  - `Numpad` - Configurable input pad
  - `Header` - Game title and navigation
  - `ScoreColumn` - Table display component
  - `SummaryDialog` - End-game results

#### Interfaces (`/interfaces`)
- **Purpose**: Define contracts for controllers and components
- **Key Interfaces**:
  - `MenuitemController` - Game initialization contract
  - `NumpadController` - Input handling contract

## Architectural Patterns

### State Management
- **Framework**: Provider package
- **Pattern**: ChangeNotifier-based controllers
- **Scope**: Global providers for all game controllers
- **State Flow**: UI → Controller → State Change → UI Update

### MVC Architecture
- **Model**: Data structures within controllers + GetStorage persistence
- **View**: Flutter widgets in `/view` directory
- **Controller**: Game logic classes in `/controller` directory

### Dependency Injection
- **Method**: Provider MultiProvider at app root
- **Scope**: All game controllers provided globally
- **Access**: Views consume controllers via `Provider.of<T>(context)`

## Game Workflow

### Application Lifecycle

1. **App Initialization**
   - Initialize GetStorage for all games
   - Set landscape orientation
   - Setup Provider tree with all controllers

2. **Menu Navigation**
   - Display 4x5 grid of available games
   - Each game represented by `MenuItem` with controller and view
   - Dynamic layout calculation based on screen size

3. **Game Execution**
   - Controller initialization via `init(MenuItem)`
   - View rendering with real-time state updates
   - User input handling through numpad interface
   - Continuous state persistence to local storage

4. **Game Completion**
   - Summary dialog with game results
   - Statistics update and persistence
   - Return to main menu

### Data Flow

```
User Input → Numpad → Controller.pressNumpadButton() → 
State Update → notifyListeners() → View Rebuild → UI Update
```

### Persistence Strategy
- **Technology**: GetStorage (local key-value storage)
- **Scope**: Per-game storage containers
- **Data**: Game statistics, records, and historical data
- **Timing**: Real-time updates during gameplay

## Game Types and Categories

### Training Games
- **Checkout Games**: 170x10, 501x5 - Practice finishing combinations
- **Accuracy Games**: Round the Clock variants - Precision training
- **Finish Training**: FinishQuest series - Learn finishing routes
- **Specialty Games**: Kill Bull, Speed Bull - Specific skill focus

### Skill Development Games
- **Double Path**: Practice common double finishing sequences
- **10 Up 1 Down**: Progressive target challenge
- **2 Darts**: Two-dart finishing practice
- **Check 121**: Specific checkout scenario training

### Assessment Games
- **Bob's 27**: Double round the clock challenge
- **Half It**: Accuracy under pressure
- **Catch 40**: Finishing from various scores

## Technical Implementation Details

### Controller Architecture
- **Singleton Pattern**: Each controller maintains single instance
- **State Variables**: Game-specific data (scores, rounds, targets)
- **Methods**: 
  - `init()` - Game setup and reset
  - `pressNumpadButton()` - Input processing
  - `getStats()` - Statistics formatting
  - Display methods for UI data formatting

### UI Components
- **Responsive Design**: Dynamic layout calculation
- **Consistent Styling**: Centralized style definitions
- **Configurable Numpad**: Flexible input interface
- **Table Display**: Scrollable game progress tables

### Data Persistence
- **Local Storage**: GetStorage for offline capability
- **Statistics Tracking**: Comprehensive performance metrics
- **Record Keeping**: Personal bests and achievements
- **Data Structure**: Key-value pairs per game type

## Development Patterns

### Adding New Games

1. **Create Controller**
   - Extend `ControllerBase`
   - Implement required interfaces
   - Define game-specific logic and state

2. **Create View**
   - Implement consistent layout structure
   - Configure numpad for game requirements
   - Setup statistics display

3. **Integration**
   - Add controller to Provider tree in `main.dart`
   - Create MenuItem in `menu.dart`
   - Import necessary dependencies

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
- **Memory Management**: Singleton pattern for controllers
- **UI Rebuilds**: Provider-based selective updates

### Data Storage
- **Local Persistence**: Fast GetStorage operations
- **Minimal Data**: Efficient storage structure
- **Batch Operations**: Grouped storage updates

### UI Rendering
- **Landscape Orientation**: Optimized for tablet/phone landscape
- **Dynamic Layouts**: Responsive design patterns
- **Efficient Widgets**: Stateless widgets where possible

## Future Extensibility

### Adding Games
- **Modular Design**: Easy addition of new game types
- **Consistent Patterns**: Established development workflow
- **Flexible Components**: Reusable UI elements

### Feature Enhancement
- **Statistics System**: Expandable metrics tracking
- **UI Components**: Modular widget architecture
- **Data Export**: Extensible storage system

### Platform Support
- **Cross-Platform**: Flutter's native capabilities
- **Responsive Design**: Adaptable to different screen sizes
- **Offline Capability**: Local storage independence

## Dependencies

### Core Dependencies
- **flutter**: UI framework
- **provider**: State management
- **get_storage**: Local data persistence

### Development Tools
- **flutter_lints**: Code quality
- **Standard Flutter toolchain**: Build and deployment

## Build and Deployment

### Development
- **Environment**: Flutter SDK
- **IDE**: Any Flutter-supported IDE
- **Testing**: Flutter analyze for code quality

### Production
- **Platforms**: Android APK/iOS IPA
- **Orientation**: Landscape mode only
- **Storage**: Local device storage only

---

*This documentation provides a high-level overview of the DART Training App architecture and development patterns. For specific implementation details, refer to the source code and inline comments.*
