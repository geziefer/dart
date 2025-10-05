import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart/widget/cricket_board.dart';

void main() {
  group('Cricket Board Widget Tests', () {
    testWidgets('CricketBoard displays all cricket numbers', (WidgetTester tester) async {
      final hits = <int, int>{
        15: 0, 16: 0, 17: 0, 18: 0, 19: 0, 20: 0, 25: 0
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CricketBoard(hits: hits),
          ),
        ),
      );

      // Check that all cricket numbers are displayed
      expect(find.text('15'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('19'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('B'), findsOneWidget); // Bull
    });

    testWidgets('CricketBoard displays hit indicators correctly', (WidgetTester tester) async {
      final hits = <int, int>{
        15: 1, 16: 2, 17: 3, 18: 0, 19: 1, 20: 2, 25: 3
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CricketBoard(hits: hits),
          ),
        ),
      );

      // Each number should have 3 circles (filled or empty)
      // Total circles = 7 numbers × 3 circles = 21 circles
      expect(find.text('●'), findsWidgets); // Filled circles
      expect(find.text('◯'), findsWidgets); // Empty circles
    });

    testWidgets('CricketBoard handles zero hits', (WidgetTester tester) async {
      final hits = <int, int>{
        15: 0, 16: 0, 17: 0, 18: 0, 19: 0, 20: 0, 25: 0
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CricketBoard(hits: hits),
          ),
        ),
      );

      // All circles should be empty
      expect(find.text('◯'), findsNWidgets(21)); // 7 numbers × 3 circles
      expect(find.text('●'), findsNothing);
    });

    testWidgets('CricketBoard handles maximum hits', (WidgetTester tester) async {
      final hits = <int, int>{
        15: 3, 16: 3, 17: 3, 18: 3, 19: 3, 20: 3, 25: 3
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CricketBoard(hits: hits),
          ),
        ),
      );

      // All circles should be filled
      expect(find.text('●'), findsNWidgets(21)); // 7 numbers × 3 circles
      expect(find.text('◯'), findsNothing);
    });

    testWidgets('CricketBoard handles partial hits', (WidgetTester tester) async {
      final hits = <int, int>{
        15: 1, 16: 2, 17: 3, 18: 0, 19: 1, 20: 2, 25: 1
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CricketBoard(hits: hits),
          ),
        ),
      );

      // Should have mix of filled and empty circles
      // 15: 1 filled, 2 empty
      // 16: 2 filled, 1 empty  
      // 17: 3 filled, 0 empty
      // 18: 0 filled, 3 empty
      // 19: 1 filled, 2 empty
      // 20: 2 filled, 1 empty
      // 25: 1 filled, 2 empty
      // Total: 10 filled, 11 empty
      expect(find.text('●'), findsNWidgets(10));
      expect(find.text('◯'), findsNWidgets(11));
    });

    testWidgets('CricketBoard layout structure', (WidgetTester tester) async {
      final hits = <int, int>{
        15: 0, 16: 0, 17: 0, 18: 0, 19: 0, 20: 0, 25: 0
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CricketBoard(hits: hits),
          ),
        ),
      );

      // Check main structure
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Padding), findsNWidgets(7)); // One padding per number
    });

    testWidgets('CricketBoard responsive sizing', (WidgetTester tester) async {
      final hits = <int, int>{
        15: 0, 16: 0, 17: 0, 18: 0, 19: 0, 20: 0, 25: 0
      };

      // Test with different screen sizes
      await tester.binding.setSurfaceSize(const Size(400, 800)); // Phone size
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CricketBoard(hits: hits),
          ),
        ),
      );

      expect(find.byType(CricketBoard), findsOneWidget);
      
      // Test with tablet size
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pump();
      
      expect(find.byType(CricketBoard), findsOneWidget);
    });
  });
}
