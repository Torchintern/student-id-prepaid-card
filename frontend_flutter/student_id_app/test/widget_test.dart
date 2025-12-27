import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_id_prepaid_card/main.dart';

void main() {
  testWidgets('App launches and shows Login screen', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Allow initial frames to render
    await tester.pumpAndSettle();

    // Verify Login screen text
    expect(find.text('Login'), findsOneWidget);

    // Verify role toggle buttons exist
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Merchant'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);

    // Verify mobile number input field exists
    expect(find.byType(TextField), findsWidgets);

    // Verify SEND OTP button exists
    expect(find.text('SEND OTP'), findsOneWidget);
  });

  testWidgets('Role switch updates login title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Default role is Student
    expect(find.text('student Login'), findsOneWidget);

    // Switch to Merchant
    await tester.tap(find.text('Merchant'));
    await tester.pumpAndSettle();
    expect(find.text('merchant Login'), findsOneWidget);

    // Switch to Admin
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(find.text('admin Login'), findsOneWidget);
  });
}
