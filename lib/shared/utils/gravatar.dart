import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:conectenis_app/shared/utils/media_url.dart';

/// Builds a Gravatar URL from the user's e-mail (MD5 hash, lowercase trimmed).
String gravatarUrl(
  String email, {
  int size = 256,
  String defaultImage = 'identicon',
}) {
  final normalized = email.trim().toLowerCase();
  if (normalized.isEmpty) return '';
  final hash = md5.convert(utf8.encode(normalized)).toString();
  return 'https://www.gravatar.com/avatar/$hash?s=$size&d=$defaultImage';
}

/// Prefers API [avatarUrl] when present; otherwise falls back to Gravatar via [email].
String resolveAvatarUrl({
  String? avatarUrl,
  String? email,
  bool hasCustomAvatar = false,
}) {
  if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
    final resolved = resolveMediaUrl(avatarUrl);
    if (resolved.isNotEmpty) return resolved;
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return resolveMediaUrl(avatarUrl);
    }
  }

  if (!hasCustomAvatar && email != null && email.trim().isNotEmpty) {
    return gravatarUrl(email);
  }

  return '';
}
