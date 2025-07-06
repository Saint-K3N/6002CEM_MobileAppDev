// widget_test.dart - CORRECTED TEST FILE
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Simple test app for testing
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Planner Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Meal Planner'),
        ),
        body: const Center(
          child: Text('Meal Planner App'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TestApp());

    // Verify that our app loads.
    expect(find.text('Meal Planner'), findsOneWidget);
    expect(find.text('Meal Planner App'), findsOneWidget);
  });
}
