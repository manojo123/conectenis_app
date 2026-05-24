import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  /// Resolves [API_BASE_URL] for the current platform (emulator vs desktop).
  static String get apiBaseUrl {
    final configured = dotenv.env['API_BASE_URL'];
    if (configured != null && configured.isNotEmpty) {
      return _resolveForPlatform(configured);
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2/api';
    }
    return 'http://localhost/api';
  }

  static String _resolveForPlatform(String url) {
    if (kIsWeb) return url;

    var resolved = url;
    if (Platform.isAndroid) {
      resolved = resolved
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
      // Sail on this project uses host port 80, not 8000.
      resolved = resolved.replaceAll(':8000', '');
    }
    return resolved;
  }

  static bool get useMockApi =>
      (dotenv.env['USE_MOCK_API'] ?? 'true').toLowerCase() == 'true';

  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  /// OAuth 2.0 **Web application** client ID (same value as Laravel `GOOGLE_CLIENT_ID`).
  static String get googleOAuthWebClientId =>
      dotenv.env['GOOGLE_OAUTH_WEB_CLIENT_ID'] ?? '';

  /// OAuth 2.0 **iOS** client ID (optional; required for Google Sign-In on iPhone).
  static String get googleOAuthIosClientId =>
      dotenv.env['GOOGLE_OAUTH_IOS_CLIENT_ID'] ?? '';

  static String get reverbAppKey => dotenv.env['REVERB_APP_KEY'] ?? '';

  static String get reverbHost => dotenv.env['REVERB_HOST'] ?? 'http://laravel.test';

  static int get reverbPort => int.tryParse(dotenv.env['REVERB_PORT'] ?? '') ?? 8080;

  static String get reverbScheme => dotenv.env['REVERB_SCHEME'] ?? 'http';

  static bool get reverbEnabled => reverbAppKey.isNotEmpty;
}
