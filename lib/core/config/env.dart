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

  static String get googleMapsApiKey {
    var raw = (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '').trim();
    if (raw.length >= 2) {
      if (raw.startsWith('"') && raw.endsWith('"')) {
        raw = raw.substring(1, raw.length - 1);
      } else if (raw.startsWith("'") && raw.endsWith("'")) {
        raw = raw.substring(1, raw.length - 1);
      }
    }
    return raw;
  }

  /// Google Maps Flutter only supports Android and iOS (not Windows/macOS/Linux).
  static bool get isGoogleMapsNativePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Whether to render [GoogleMap]. On mobile, the key is injected at build time
  /// (Android: `android/local.properties` or `.env` via Gradle). Do not require
  /// [googleMapsApiKey] from Dart dotenv — that only gates Dart-side checks.
  static bool get isGoogleMapsSupported => isGoogleMapsNativePlatform;

  static bool get hasGoogleMapsApiKeyInEnv => googleMapsApiKey.isNotEmpty;

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

  static String get appShareUrl =>
      dotenv.env['APP_SHARE_URL'] ?? 'https://conectenis.com.br';

  static String get legalTermsUrl =>
      dotenv.env['LEGAL_TERMS_URL'] ?? 'https://conectenis.com.br/termos';

  static String get legalPrivacyUrl =>
      dotenv.env['LEGAL_PRIVACY_URL'] ?? 'https://conectenis.com.br/privacidade';

  static String get legalVersion =>
      dotenv.env['LEGAL_VERSION'] ?? '2026-05-23';

  /// Rewrites localhost in any URL (e.g. avatar links from Laravel).
  static String resolveHostForPlatform(String url) {
    if (kIsWeb) return url;
    var resolved = url;
    if (Platform.isAndroid) {
      resolved = resolved
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
      resolved = resolved.replaceAll(':8000', '');
    }
    return resolved;
  }
}
