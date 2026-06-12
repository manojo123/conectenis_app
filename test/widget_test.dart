import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conectenis_app/features/auth/presentation/login_screen.dart';
import 'package:conectenis_app/features/auth/providers/auth_provider.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';

class _LoggedOutAuthNotifier extends AuthNotifier {
  @override
  Future<UserProfile?> build() async => null;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: 'USE_MOCK_API=true\n');
  });

  testWidgets('Login screen shows brand and primary actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_LoggedOutAuthNotifier.new),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.bySemanticsLabel('ConecTênis'), findsOneWidget);
    expect(find.text('CONECTE-SE OU CADASTRE-SE'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
  });
}
