import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:conectenis_app/app/app.dart';
import 'package:conectenis_app/core/storage/settings_storage.dart';
import 'package:conectenis_app/core/theme/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('pt_BR');
  final storedTheme = await const SettingsStorage().readThemeMode();
  final initialMode =
      storedTheme == ThemeMode.light.name ? ThemeMode.light : ThemeMode.dark;
  runApp(
    ProviderScope(
      overrides: [initialThemeModeProvider.overrideWithValue(initialMode)],
      child: const ConecTenisApp(),
    ),
  );
}
