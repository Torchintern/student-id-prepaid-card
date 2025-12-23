import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_id_system/screens/login_screen.dart';

void main() {
  testWidgets('App launches and shows Login Screen',
      (WidgetTester tester) async {

    // Build the app
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Verify Login screen UI elements
    expect(find.text('Login'), findsOneWidget);

    // Role buttons
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Merchant'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);

    // Mobile number field
    expect(find.byType(TextField), findsWidgets);

    // Send OTP button
    expect(find.text('SEND OTP'), findsOneWidget);
  });
}
