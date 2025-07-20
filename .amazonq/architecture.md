# Architecture Documentation

## Overall Architecture Pattern
The DART training app follows the **Model-View-Controller (MVC)** pattern with Flutter-specific adaptations.

## Directory Structure & Responsibilities

### `/lib/controller/`
**Purpose**: Business logic and state management
- Handle user interactions
- Manage application state
- Coordinate between models and views
- Implement business rules
- Each controller of a game has a related view

### `/lib/view/`
**Purpose**: UI screens and page-level components
- Represent complete screens/pages
- Handle navigation
- Coordinate multiple widgets
- Manage screen-specific state
- Each view of a game has a related controller

### `/lib/widget/`
**Purpose**: Reusable UI components
- Stateless widgets
- Reusable across multiple views
- Encapsulate specific UI functionality
- Follow single responsibility principle

### `/lib/interfaces/`
**Purpose**: Abstract contracts and interfaces
- Define contracts for services
- Abstract data access patterns
- Enable dependency injection
- Support testing with mocks

## Data Flow Architecture

```
User Input → View → Controller → Model/Service → Database
                ↓
            Widget Updates ← State Changes ← Business Logic
```

### Key Principles
1. **Separation of Concerns**: Each layer has distinct responsibilities
2. **Dependency Inversion**: Controllers depend on interfaces, not implementations
3. **Single Responsibility**: Each class has one reason to change
4. **Testability**: Business logic is isolated and testable

## State Management Strategy

### Application State (App-level)
- Provider for game session logic

### Persistent State
- Local Storage with Key-Value-Map per id
