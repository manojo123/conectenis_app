import 'package:conectenis_app/core/config/env.dart';

/// Turns Laravel relative storage paths into absolute URLs for [Image.network].
String resolveMediaUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final trimmed = url.trim();
  final origin = Env.resolveHostForPlatform(
    Env.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), ''),
  );

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.path.startsWith('/storage/')) {
      return '$origin${uri.path}';
    }
    return Env.resolveHostForPlatform(trimmed);
  }

  if (trimmed.startsWith('/')) return '$origin$trimmed';
  return '$origin/$trimmed';
}
