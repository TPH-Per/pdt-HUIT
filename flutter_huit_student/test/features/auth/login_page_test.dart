import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_huit_student/features/auth/login_page.dart';

void main() {
  group('LoginPage Widget Tests', () {
    testWidgets('LoginPage renders smoke test',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('LoginPage basic widget structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      expect(find.byType(Material), findsWidgets);
    });
  });
}
