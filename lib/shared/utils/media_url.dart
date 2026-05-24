import 'package:conectenis_app/core/config/env.dart';

/// Turns Laravel relative storage paths into absolute URLs for [Image.network].
String resolveMediaUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final origin = Env.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
  if (trimmed.startsWith('/')) return '$origin$trimmed';
  return '$origin/$trimmed';
}
