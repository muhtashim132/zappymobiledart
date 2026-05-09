import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zappymobilenew/main.dart';

void main() {
  testWidgets('Zappy app smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const ZappyApp());
    // Verify splash screen appears
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
