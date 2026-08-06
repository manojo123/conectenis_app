import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/storage/settings_storage.dart';

/// Seed value loaded from [SettingsStorage] before `runApp` and injected via
/// a ProviderScope override in `main.dart`, so the first frame already uses
/// the persisted theme (no flash).
final initialThemeModeProvider = Provider<ThemeMode>((_) => ThemeMode.dark);

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(initialThemeModeProvider);

  void toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  void set(ThemeMode mode) {
    state = mode;
    ref.read(settingsStorageProvider).writeThemeMode(mode.name);
  }
}
