# DART Training App - Project Context

## Project Overview
- **Name**: DART (Damit Alex Richtig Trainiert)
- **Purpose**: Personal Dart training application 
- **Target Device**: Google Pixel C (tablet optimized)
- **Framework**: Flutter/Dart
- **Architecture**: MVC pattern

## Business Rules

### Game Rules
- Each game is reachable via a MenuItem from the main menu, it gets parametrized and a reference to a controller and a view which are game specific, but follow a pattern by its interface
- Each game consists of a number of rounds and at the end shows a summary dialog with the results
- The results are persisted in a local store to get overall statistics
- The game is designed for a single player only (the author of the app) to improve his Dart skills via training games, this implies knowing how to play the game and what to input and thus does not need a "dummy-proof" attitude for the public

### UI/UX Rules
- Optimized for tablet landscape orientation (Google Pixel C), the game will only be played on this device, so no other device or display form is needed
- The game starts with a main menu and returns to it after each game
- Each game has the same basic design: On top there is a logo, the main content area is split in half vertically with the left side containing some table or text output of the results and the right side provide an input for the game, typically a numpad but for some games a full dartboard with inputs for each field, and finally, the bottom part contains statistic for the game and overall
- If a game consists of several rounds, there is a popup message for end of game with a button that automatically does OK after some time
- At the end of each game there is a summary dialog showing the results of the game
- Every game can be quit with a global back button to the menu, then it will not be countet for statistics

### Data Rules
- The data for the statistics is stored in a local Storage which is just a key value map with entry ids for each game
- There is no external database or service over the network

## Domain Terminology
- Dart: A sport where the player has to hit a board on special fields by throwing 3 dart arrows
- Dart board: A round-shaaped board consisting of the following parts:
  - 20 pie sliced areas of the same size for the numbers 1 to 20, the order of the numbers are clockwise from the top: 20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5
  - Each slice is devided from top to bottom in: a small area for double points, a large single field, a small area for triple points, a small single field
  - A circle in the middle, consisting of an inner and outer part (25 / 50)
  - An outside area (0)
- Dart training game: A single player game with a special training aspect, e.g. scoring, doubles, finish ways, special fields - the purpose is always to reach as many points / finish as fast as possible in a certain number of rounds as possible 
