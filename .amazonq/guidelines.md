# Development Guidelines

## General Behavior
- Don't say "You are absolutely right" when you are pointed to errors in proposals, just do it correctly then

## Git & Verification Workflow (MUST FOLLOW)
- **Never commit without explicit user approval.** After making changes, let the
  user test them first. Only create a git commit once the user has tested and
  confirmed the changes work.
- **Always keep build and tests green.** Before presenting any change as done,
  run `flutter analyze` (must be clean) and `flutter test` (must pass). If either
  fails, fix it before handing the change back for testing.
- Order of operations for every change: implement → `flutter analyze` + `flutter test`
  green → hand over for the user to test → commit only after the user confirms.

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
- Always let the user test changes before committing them to git
- Always ensure `flutter analyze` is clean and `flutter test` passes before
  handing changes over for testing (see Git & Verification Workflow above)
