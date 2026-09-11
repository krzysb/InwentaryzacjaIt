import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inwentaryzacja_it/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('Ekran logowania pokazuje pola e-mail i haslo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    expect(find.text('Inwentaryzacja IT'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'E-mail'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Haslo'), findsOneWidget);
  });
}
