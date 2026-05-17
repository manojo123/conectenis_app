import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://laravel.test/api';

  static bool get useMockApi =>
      (dotenv.env['USE_MOCK_API'] ?? 'true').toLowerCase() == 'true';

  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static String get reverbAppKey => dotenv.env['REVERB_APP_KEY'] ?? '';

  static String get reverbHost => dotenv.env['REVERB_HOST'] ?? 'http://laravel.test';

  static int get reverbPort => int.tryParse(dotenv.env['REVERB_PORT'] ?? '') ?? 8080;

  static String get reverbScheme => dotenv.env['REVERB_SCHEME'] ?? 'http';

  static bool get reverbEnabled => reverbAppKey.isNotEmpty;
}
