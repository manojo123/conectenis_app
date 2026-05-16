import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conectenis_app/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('Login screen shows brand', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('ConecTenis'), findsOneWidget);
    expect(find.text('Sua Conexão no Tênis'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
