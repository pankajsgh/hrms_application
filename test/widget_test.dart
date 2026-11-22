import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hrms/main.dart';

void main() {
  testWidgets('HRMS App login smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HrmsApp());
    expect(find.text('Sign in'), findsWidgets);
  });
}
