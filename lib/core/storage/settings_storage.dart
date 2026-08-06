import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small key-value store for app preferences (currently just the theme).
class SettingsStorage {
  const SettingsStorage();

  static const _themeModeKey = 'theme_mode';
  static const _storage = FlutterSecureStorage();

  /// Returns `'dark'` / `'light'`, or null when never set.
  Future<String?> readThemeMode() async {
    try {
      return await _storage.read(key: _themeModeKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeThemeMode(String value) async {
    try {
      await _storage.write(key: _themeModeKey, value: value);
    } catch (_) {
      // Persisting the theme is best-effort; never surface storage errors.
    }
  }
}

final settingsStorageProvider =
    Provider<SettingsStorage>((_) => const SettingsStorage());
