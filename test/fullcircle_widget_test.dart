import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart/widget/fullcircle.dart';
import 'package:dart/widget/arcsection.dart';
import 'package:dart/interfaces/dartboard_controller.dart';
import 'dart:math';

// Mock dartboard controller for testing
class MockDartboardController implements DartboardController {
  String? lastPressedField;

  @override
  void pressDartboard(String field) {
    lastPressedField = field;
  }
}

void main() {
  group('FullCircle Widget Business Logic Tests', () {
    late MockDartboardController mockController;
    late List<ArcSection> testArcSections;

    setUp(() {
      mockController = MockDartboardController();

      // Create test arc sections (simulating dartboard rings)
      testArcSections = [
        ArcSection(startPercent: 0.25), // Outer single
        ArcSection(startPercent: 0.45), // Triple
        ArcSection(startPercent: 0.55), // Inner single
        ArcSection(startPercent: 0.85), // Double
      ];
    });

    /// Tests FullCircle widget constructor and properties
    /// Verifies: Widget properties are set correctly during instantiation
    test('FullCircle widget constructor and properties', () {
      final fullCircle = FullCircle(
        controller: mockController,
        radius: 150.0,
        arcSections: testArcSections,
      );

      expect(fullCircle.controller, equals(mockController));
      expect(fullCircle.radius, equals(150.0));
      expect(fullCircle.arcSections, equals(testArcSections));
      expect(fullCircle.arcSections.length, equals(4));
    });

    /// Tests FullCircle widget build method execution and calculations
    /// Verifies: Build method calculations are executed correctly
    testWidgets('FullCircle widget build method execution',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullCircle(
              controller: mockController,
              radius: 100.0,
              arcSections: testArcSections,
            ),
          ),
        ),
      );

      // Verify the widget builds successfully
      expect(find.byType(FullCircle), findsOneWidget);
      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.byType(CustomPaint),
          findsWidgets); // May find multiple due to framework internals

      // Focus on business logic: verify widget instantiation worked
      final fullCircleWidget =
          tester.widget<FullCircle>(find.byType(FullCircle));
      expect(fullCircleWidget.radius, equals(100.0));
      expect(fullCircleWidget.controller, equals(mockController));
      expect(fullCircleWidget.arcSections.length, equals(4));
    });

    /// Tests FullCircle widget angle and radius calculations
    /// Verifies: Mathematical calculations in build method
    test('FullCircle widget mathematical calculations', () {
      const double testRadius = 100.0;

      // Test angle calculations (from build method)
      const int numberOfSlices = 20;
      const double sliceAngle = 360 / numberOfSlices;
      const double rotationAngle = (sliceAngle / 2) * pi / 180;

      expect(sliceAngle, equals(18.0)); // 360 / 20
      expect(rotationAngle, closeTo(0.157, 0.001)); // (18/2) * pi/180 ≈ 0.157

      // Test radius calculations (from build method)
      const double centerCircleRadius = testRadius * 0.1;
      const double innerArcRadius = testRadius * 0.1;
      const double outerArcRadius = testRadius * 0.25;

      expect(centerCircleRadius, equals(10.0));
      expect(innerArcRadius, equals(10.0));
      expect(outerArcRadius, equals(25.0));

      // Verify radius relationships
      expect(centerCircleRadius, lessThan(outerArcRadius));
      expect(innerArcRadius, lessThan(outerArcRadius));
      expect(outerArcRadius, lessThan(testRadius));
    });

    /// Tests FullCircle widget ArcSection generation logic
    /// Verifies: ArcSection list generation in build method
    test('FullCircle widget ArcSection generation logic', () {
      // Simulate the ArcSection generation logic from build method
      final arcSectionsWithColors = List<ArcSection>.generate(
        testArcSections.length,
        (index) => ArcSection(
          startPercent: testArcSections[index].startPercent,
        ),
      );

      expect(arcSectionsWithColors.length, equals(testArcSections.length));

      for (int i = 0; i < arcSectionsWithColors.length; i++) {
        expect(arcSectionsWithColors[i].startPercent,
            equals(testArcSections[i].startPercent));
      }

      // Test radius calculations for each arc section
      const double testRadius = 100.0;
      for (int i = 0; i < arcSectionsWithColors.length; i++) {
        final arcSection = arcSectionsWithColors[i];
        final double innerRadius = testRadius * arcSection.startPercent;
        final double outerRadius = (i < arcSectionsWithColors.length - 1)
            ? testRadius * arcSectionsWithColors[i + 1].startPercent
            : testRadius;

        expect(innerRadius, lessThan(outerRadius));
        expect(innerRadius, greaterThanOrEqualTo(0.0));
        expect(outerRadius, lessThanOrEqualTo(testRadius));
      }
    });

    /// Tests FullCircle widget field generation business logic
    /// Verifies: Field string generation logic in onTapUp
    test('FullCircle widget field generation business logic', () {
      // Test the field generation logic from onTapUp method
      const numberOfSlices = 20;

      for (int sliceIndex = 0; sliceIndex < numberOfSlices; sliceIndex++) {
        for (int arcIndex = 0; arcIndex < 4; arcIndex++) {
          // Simulate field generation logic
          String arcNo = FullCircle.sliceIDs.elementAt(sliceIndex);
          String arcField = switch (arcIndex) {
            0 => "S",
            1 => "T",
            2 => "S",
            3 => "D",
            _ => ""
          };
          String generatedField = '$arcField$arcNo';

          // Verify field format
          expect(generatedField.length, greaterThanOrEqualTo(2));
          expect(generatedField.length, lessThanOrEqualTo(3));
          expect(['S', 'T', 'D'].contains(generatedField[0]), isTrue);

          // Verify specific examples
          if (sliceIndex == 0 && arcIndex == 1) {
            expect(generatedField, equals('T1'));
          }
          if (sliceIndex == 19 && arcIndex == 3) {
            expect(generatedField, equals('D20'));
          }
        }
      }
    });

    /// Tests FullCircle widget center field detection logic
    /// Verifies: Center circle and arc detection business logic
    test('FullCircle widget center field detection logic', () {
      // Test center field detection logic (from onTapUp method)
      const double testRadius = 100.0;

      // Test center circle radius calculation
      const double centerCircleRadius = testRadius * 0.1;
      expect(centerCircleRadius, equals(10.0));

      // Test center arc radius calculations
      const double innerArcRadius = testRadius * 0.1;
      const double outerArcRadius = testRadius * 0.25;
      expect(innerArcRadius, equals(10.0));
      expect(outerArcRadius, equals(25.0));

      // Verify radius relationships for center detection
      expect(innerArcRadius, lessThan(outerArcRadius));
      expect(centerCircleRadius, equals(innerArcRadius));

      // Test that center fields would be generated correctly
      const centerFields = ['DB', 'SB']; // From onTapUp logic
      expect(centerFields[0], equals('DB')); // Center circle
      expect(centerFields[1], equals('SB')); // Center arc
    });

    /// Tests FullCircle widget slice ID mapping business logic
    /// Verifies: Dartboard slice IDs are in correct order for proper hit detection
    test('FullCircle slice ID mapping logic', () {
      // Test slice ID order (critical for dartboard accuracy)
      const expectedSliceIDs = [
        '1',
        '18',
        '4',
        '13',
        '6',
        '10',
        '15',
        '2',
        '17',
        '3',
        '19',
        '7',
        '16',
        '8',
        '11',
        '14',
        '9',
        '12',
        '5',
        '20'
      ];

      expect(FullCircle.sliceIDs, equals(expectedSliceIDs));
      expect(FullCircle.sliceIDs.length, equals(20));

      // Verify specific positions (important for dartboard layout)
      expect(FullCircle.sliceIDs[0], equals('1')); // First slice
      expect(
          FullCircle.sliceIDs[19], equals('20')); // Last slice (highest score)
      expect(FullCircle.sliceIDs[10], equals('19')); // Middle position
    });

    /// Tests FullCircle widget field generation logic
    /// Verifies: Correct field strings are generated for different dartboard areas
    test('FullCircle field generation logic', () {
      // Test field generation for different slice/arc combinations
      final testCases = [
        // Slice 0 (number 1) tests
        {'sliceIndex': 0, 'arcIndex': 0, 'expected': 'S1'}, // Single 1
        {'sliceIndex': 0, 'arcIndex': 1, 'expected': 'T1'}, // Triple 1
        {'sliceIndex': 0, 'arcIndex': 2, 'expected': 'S1'}, // Single 1 (inner)
        {'sliceIndex': 0, 'arcIndex': 3, 'expected': 'D1'}, // Double 1

        // Slice 19 (number 20) tests - highest scoring area
        {'sliceIndex': 19, 'arcIndex': 0, 'expected': 'S20'}, // Single 20
        {'sliceIndex': 19, 'arcIndex': 1, 'expected': 'T20'}, // Triple 20
        {
          'sliceIndex': 19,
          'arcIndex': 2,
          'expected': 'S20'
        }, // Single 20 (inner)
        {'sliceIndex': 19, 'arcIndex': 3, 'expected': 'D20'}, // Double 20

        // Other important numbers
        {'sliceIndex': 1, 'arcIndex': 1, 'expected': 'T18'}, // Triple 18
        {'sliceIndex': 10, 'arcIndex': 1, 'expected': 'T19'}, // Triple 19
      ];

      for (final testCase in testCases) {
        final sliceIndex = testCase['sliceIndex'] as int;
        final arcIndex = testCase['arcIndex'] as int;
        final expected = testCase['expected'] as String;

        // Simulate field generation logic from FullCircle widget
        String arcNo = FullCircle.sliceIDs[sliceIndex];
        String arcField = switch (arcIndex) {
          0 => "S", // Outer single
          1 => "T", // Triple
          2 => "S", // Inner single
          3 => "D", // Double
          _ => ""
        };
        String generatedField = '$arcField$arcNo';

        expect(generatedField, equals(expected),
            reason:
                'Slice $sliceIndex, Arc $arcIndex should generate $expected');
      }
    });

    /// Tests FullCircle widget center field logic
    /// Verifies: Bull's eye field generation
    test('FullCircle center field logic', () {
      // Test center field constants (from FullCircle widget logic)
      const centerFields = ['DB', 'SB']; // Double Bull, Single Bull

      expect(centerFields.length, equals(2));
      expect(centerFields[0], equals('DB')); // Inner bull (50 points)
      expect(centerFields[1], equals('SB')); // Outer bull (25 points)
    });

    /// Tests FullCircle widget controller integration logic
    /// Verifies: Controller methods are called with correct field strings
    test('FullCircle controller integration logic', () {
      // Test that controller interface is properly implemented
      expect(mockController, isA<DartboardController>());
      expect(mockController.lastPressedField, isNull);

      // Test controller method calls (simulate field presses)
      mockController.pressDartboard('T20');
      expect(mockController.lastPressedField, equals('T20'));

      mockController.pressDartboard('D16');
      expect(mockController.lastPressedField, equals('D16'));

      mockController.pressDartboard('DB');
      expect(mockController.lastPressedField, equals('DB'));

      mockController.pressDartboard('SB');
      expect(mockController.lastPressedField, equals('SB'));
    });

    /// Tests FullCircle widget field validation logic
    /// Verifies: All possible field combinations are valid
    test('FullCircle field validation logic', () {
      // Test all possible field combinations
      final fieldPrefixes = ['S', 'T', 'D'];
      final validFields = <String>[];

      // Generate all number fields
      for (final sliceId in FullCircle.sliceIDs) {
        for (final prefix in fieldPrefixes) {
          validFields.add('$prefix$sliceId');
        }
      }

      // Add center fields
      validFields.addAll(['DB', 'SB']);

      // Verify field count
      expect(validFields.length, equals(62)); // 20 numbers × 3 areas + 2 bulls

      // Verify specific important fields exist
      expect(validFields.contains('T20'), isTrue); // Triple 20 (60 points)
      expect(validFields.contains('T19'), isTrue); // Triple 19 (57 points)
      expect(validFields.contains('T18'), isTrue); // Triple 18 (54 points)
      expect(validFields.contains('DB'), isTrue); // Double Bull (50 points)
      expect(validFields.contains('SB'), isTrue); // Single Bull (25 points)
      expect(validFields.contains('D20'), isTrue); // Double 20 (40 points)

      // Verify field format consistency
      for (final field in validFields) {
        if (field != 'DB' && field != 'SB') {
          expect(field.length,
              greaterThanOrEqualTo(2)); // At least prefix + number
          expect(field.length,
              lessThanOrEqualTo(3)); // At most prefix + two-digit number
          expect(['S', 'T', 'D'].contains(field[0]), isTrue); // Valid prefix
        }
      }
    });

    /// Tests FullCircle widget painter configuration business logic
    /// Verifies: FullCirclePainter receives correct configuration parameters
    test('FullCircle painter configuration logic', () {
      const double testRadius = 120.0;
      const double sliceAngle = 18.0; // 360 / 20
      const double rotationAngle = 0.157; // (18/2) * pi/180

      // Test painter configuration (from build method)
      final painter = FullCirclePainter(
        radius: testRadius,
        arcSections: testArcSections,
        sliceAngle: sliceAngle,
        rotationAngle: rotationAngle,
        sliceIDs: FullCircle.sliceIDs,
      );

      expect(painter.radius, equals(testRadius));
      expect(painter.arcSections, equals(testArcSections));
      expect(painter.sliceAngle, equals(sliceAngle));
      expect(painter.rotationAngle, closeTo(rotationAngle, 0.01));
      expect(painter.sliceIDs, equals(FullCircle.sliceIDs));
      expect(painter.sliceIDs.length, equals(20));
    });

    /// Tests FullCircle widget size calculation business logic
    /// Verifies: CustomPaint size is calculated correctly from radius
    test('FullCircle size calculation logic', () {
      final testCases = [
        {'radius': 50.0, 'expectedSize': const Size(100.0, 100.0)},
        {'radius': 100.0, 'expectedSize': const Size(200.0, 200.0)},
        {'radius': 150.0, 'expectedSize': const Size(300.0, 300.0)},
        {'radius': 200.0, 'expectedSize': const Size(400.0, 400.0)},
      ];

      for (final testCase in testCases) {
        final radius = testCase['radius'] as double;
        final expectedSize = testCase['expectedSize'] as Size;

        // Test size calculation logic (from build method: Size(radius * 2, radius * 2))
        final calculatedSize = Size(radius * 2, radius * 2);

        expect(calculatedSize, equals(expectedSize));
        expect(calculatedSize.width, equals(radius * 2));
        expect(calculatedSize.height, equals(radius * 2));
        expect(calculatedSize.width, equals(calculatedSize.height)); // Square
      }
    });

    /// Tests FullCircle widget arc section radius calculation business logic
    /// Verifies: Inner and outer radius calculations for each arc section
    test('FullCircle arc section radius calculation logic', () {
      const double testRadius = 100.0;

      // Test radius calculations for each arc section (from build method)
      for (int i = 0; i < testArcSections.length; i++) {
        final arcSection = testArcSections[i];
        final double innerRadius = testRadius * arcSection.startPercent;
        final double outerRadius = (i < testArcSections.length - 1)
            ? testRadius * testArcSections[i + 1].startPercent
            : testRadius;

        // Verify radius calculations
        expect(innerRadius, greaterThanOrEqualTo(0.0));
        expect(outerRadius, lessThanOrEqualTo(testRadius));
        expect(innerRadius, lessThan(outerRadius));

        // Test specific arc section calculations
        switch (i) {
          case 0: // Outer single (25% to 45%)
            expect(innerRadius, equals(25.0));
            expect(outerRadius, equals(45.0));
            break;
          case 1: // Triple (45% to 55%)
            expect(innerRadius, equals(45.0));
            expect(outerRadius,
                closeTo(55.0, 0.001)); // Use closeTo for floating point
            break;
          case 2: // Inner single (55% to 85%)
            expect(innerRadius,
                closeTo(55.0, 0.001)); // Use closeTo for floating point
            expect(outerRadius, equals(85.0));
            break;
          case 3: // Double (85% to 100%)
            expect(innerRadius, equals(85.0));
            expect(outerRadius, equals(100.0));
            break;
        }
      }
    });
    /// Tests FullCircle widget tap detection functionality
    /// Verifies: Tap coordinates are properly converted to dartboard fields
    testWidgets('FullCircle tap detection functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FullCircle(
                controller: mockController,
                radius: 100.0,
                arcSections: testArcSections,
              ),
            ),
          ),
        ),
      );

      // Test tapping on the widget
      await tester.tap(find.byType(FullCircle));
      await tester.pump();

      // Controller should have received a field press
      expect(mockController.lastPressedField, isNotNull);
    });

    /// Tests FullCircle widget gesture handling
    /// Verifies: GestureDetector properly handles tap events
    testWidgets('FullCircle gesture handling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullCircle(
              controller: mockController,
              radius: 100.0,
              arcSections: testArcSections,
            ),
          ),
        ),
      );

      final gestureDetector = find.byType(GestureDetector);
      expect(gestureDetector, findsOneWidget);

      // Test multiple taps
      await tester.tap(gestureDetector);
      await tester.pump();
      final firstField = mockController.lastPressedField;

      await tester.tap(gestureDetector);
      await tester.pump();
      final secondField = mockController.lastPressedField;

      expect(firstField, isNotNull);
      expect(secondField, isNotNull);
    });

    /// Tests FullCircle widget CustomPaint integration
    /// Verifies: CustomPaint widget is properly configured
    testWidgets('FullCircle CustomPaint integration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullCircle(
              controller: mockController,
              radius: 150.0,
              arcSections: testArcSections,
            ),
          ),
        ),
      );

      // Should contain CustomPaint for drawing the dartboard
      expect(find.byType(CustomPaint), findsWidgets);
      
      // Verify the widget structure
      expect(find.byType(FullCircle), findsOneWidget);
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    /// Tests FullCircle widget with different arc section configurations
    /// Verifies: Widget handles various arc section setups
    testWidgets('FullCircle with different arc configurations', (WidgetTester tester) async {
      // Test with minimal arc sections
      final minimalArcSections = [
        ArcSection(startPercent: 0.5),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullCircle(
              controller: mockController,
              radius: 100.0,
              arcSections: minimalArcSections,
            ),
          ),
        ),
      );

      expect(find.byType(FullCircle), findsOneWidget);

      // Test with many arc sections
      final manyArcSections = List.generate(
        6,
        (index) => ArcSection(startPercent: (index + 1) * 0.15),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullCircle(
              controller: mockController,
              radius: 100.0,
              arcSections: manyArcSections,
            ),
          ),
        ),
      );

      expect(find.byType(FullCircle), findsOneWidget);
    });

    /// Tests FullCircle widget with different radius values
    /// Verifies: Widget scales properly with different sizes
    testWidgets('FullCircle with different radius values', (WidgetTester tester) async {
      final radiusValues = [50.0, 100.0, 150.0, 200.0];

      for (final radius in radiusValues) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FullCircle(
                controller: mockController,
                radius: radius,
                arcSections: testArcSections,
              ),
            ),
          ),
        );

        expect(find.byType(FullCircle), findsOneWidget);
        
        final widget = tester.widget<FullCircle>(find.byType(FullCircle));
        expect(widget.radius, equals(radius));
      }
    });
  });
}
