// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anapp/main.dart';

void main() {
  testWidgets('Calendar screen shows title', (WidgetTester tester) async {
    // Build the application and trigger a frame.
    await tester.pumpWidget(const AnApp());
    // Verify that the CalendarScreen's title is present.
    expect(find.text('Calendario de Rotacion'), findsOneWidget);
  });
}
