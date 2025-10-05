import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:dart/widget/version_info.dart';

void main() {
  group('Version Info Widget Tests', () {
    setUp(() {
      // Set up mock package info
      PackageInfo.setMockInitialValues(
        appName: 'DART',
        packageName: 'com.example.dart',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
        installerStore: null,
      );
    });

    testWidgets('VersionInfo displays initial empty version', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VersionInfo(),
          ),
        ),
      );

      // Initially should show empty string
      expect(find.text(''), findsOneWidget);
    });

    testWidgets('VersionInfo displays version after loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VersionInfo(),
          ),
        ),
      );

      // Wait for the version to load
      await tester.pumpAndSettle();

      // Should display version in format "v1.0.0+1"
      expect(find.textContaining('v'), findsOneWidget);
      expect(find.textContaining('1.0.0'), findsOneWidget);
      expect(find.textContaining('+1'), findsOneWidget);
    });

    testWidgets('VersionInfo has correct text style', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VersionInfo(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.color, equals(Colors.grey[400]));
      expect(textWidget.style?.fontSize, equals(12));
    });

    testWidgets('VersionInfo widget structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VersionInfo(),
          ),
        ),
      );

      expect(find.byType(VersionInfo), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('VersionInfo handles state changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VersionInfo(),
          ),
        ),
      );

      // Initial state
      expect(find.text(''), findsOneWidget);

      // After loading
      await tester.pumpAndSettle();
      expect(find.textContaining('v'), findsOneWidget);
    });

    testWidgets('VersionInfo version format validation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VersionInfo(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFinder = find.byType(Text);
      final textWidget = tester.widget<Text>(textFinder);
      final versionText = textWidget.data ?? '';

      // Should match pattern "v{version}+{buildNumber}"
      expect(versionText, matches(r'^v\d+\.\d+\.\d+\+\d+$'));
    });

    testWidgets('VersionInfo multiple instances', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                VersionInfo(),
                VersionInfo(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Both instances should show the same version
      expect(find.byType(VersionInfo), findsNWidgets(2));
      expect(find.textContaining('v1.0.0+1'), findsNWidgets(2));
    });

    testWidgets('VersionInfo async loading behavior', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VersionInfo(),
          ),
        ),
      );

      // Should start with empty version
      final initialText = tester.widget<Text>(find.byType(Text));
      expect(initialText.data, equals(''));

      // Complete the async operation
      await tester.pumpAndSettle();
      
      // Now should show version
      expect(find.textContaining('v'), findsOneWidget);
    });

    testWidgets('VersionInfo widget lifecycle', (WidgetTester tester) async {
      // Test widget creation and disposal
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VersionInfo(),
          ),
        ),
      );

      expect(find.byType(VersionInfo), findsOneWidget);

      // Remove widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      expect(find.byType(VersionInfo), findsNothing);
    });
  });
}
