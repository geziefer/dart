# Development Guidelines

## General Behavior
- Don't say "You are absolutely right" when you are pointed to errors in proposals, just do it correctly then

## Coding Standards

### Dart/Flutter Conventions
- Follow official Dart style guide
- Use `lowerCamelCase` for variables and functions
- Use `UpperCamelCase` for classes and enums
- Prefer `final` over `var` when possible
- Use meaningful variable and function names
- Maximum line length: 80 characters

### Documentation Requirements
- All public classes and methods must have doc comments (`///`)
- Include usage examples for complex functions
- Document business logic and non-obvious code
- Keep comments up-to-date with code changes

### UI/UX
- Styles should go into styles.dart file if they are re-usable, like Text styles
- Styles which are specific to a widget can stay in the widget code
- In general, no UI code should be in controller

### File Organization
```
lib/
├── main.dart                # App entry point
├── styles.dart              # Global styles and themes
├── controller/              # Business logic controllers
├── view/                    # UI screens and pages
├── widget/                  # Reusable UI components
└── interfaces/              # Abstract classes and contracts
```

### Naming Conventions
- Controllers: controller_xxx
- Views: view_xxx

## Development Practices

### Code Quality
- Use meaningful commit messages
- Run `flutter analyze` after generating code
- Format code with `dart format`

### State Management
- Use provider state management solution
- Keep state immutable where possible
- Separate UI state from business state
- Handle loading and error states consistently

### Error Handling
- Log errors for debugging purposes

### Performance Guidelines
- Optimize for tablet performance
- Use `const` constructors where possible
- Implement lazy loading for large lists
- Cache frequently accessed data

### Testing Strategy
- User will test in simulator and on target device (Google Pixel C)
