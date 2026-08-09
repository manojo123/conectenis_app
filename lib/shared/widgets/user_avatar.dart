import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/shared/utils/gravatar.dart';

/// Prototype avatar hues - initials render on a gradient derived from the
/// user id so every player gets a stable, distinct color.
const _avatarHues = [210.0, 160.0, 25.0, 285.0, 330.0];

/// Gradient for a user id: `linear-gradient(135°, hsl(H 45% 42%), hsl(H+30 52% 26%))`.
LinearGradient avatarGradientFor(int? userId) {
  final hue = _avatarHues[(userId ?? 0) % _avatarHues.length];
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      HSLColor.fromAHSL(1, hue, 0.45, 0.42).toColor(),
      HSLColor.fromAHSL(1, (hue + 30) % 360, 0.52, 0.26).toColor(),
    ],
  );
}

/// Up to two initials ("Rafael Costa" → "RC").
String initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'))
    ..removeWhere((p) => p.isEmpty);
  if (parts.isEmpty) return '?';
  final first = parts.first[0];
  final second = parts.length > 1 ? parts.last[0] : '';
  return (first + second).toUpperCase();
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.email,
    this.hasCustomAvatar = false,
    this.radius = 20,
    this.userId,
    this.ringColor,
    this.ringWidth = 3,
  });

  final String name;
  final String? avatarUrl;
  final String? email;
  final bool hasCustomAvatar;
  final double radius;

  /// Drives the fallback gradient hue (id % 5). Falls back to a navy circle
  /// when absent, matching the previous behavior.
  final int? userId;

  /// Lime ring on own/profile avatars (prototype); null = no ring.
  final Color? ringColor;
  final double ringWidth;

  String? get _networkUrl {
    final resolved = resolveAvatarUrl(
      avatarUrl: avatarUrl,
      email: email,
      hasCustomAvatar: hasCustomAvatar,
    );
    return resolved.isEmpty ? null : resolved;
  }

  File? get _localFile {
    if (avatarUrl == null || avatarUrl!.trim().isEmpty) return null;
    final trimmed = avatarUrl!.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return null;
    final file = File(trimmed);
    return file.existsSync() ? file : null;
  }

  @override
  Widget build(BuildContext context) {
    return _withRing(_avatar());
  }

  Widget _avatar() {
    final local = _localFile;
    if (local != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.navy,
        backgroundImage: FileImage(local),
      );
    }

    final url = _networkUrl;
    if (url != null) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => _fallback(),
            errorWidget: (context, url, error) => _fallback(),
          ),
        ),
      );
    }

    return _fallback();
  }

  Widget _withRing(Widget avatar) {
    if (ringColor == null) return avatar;
    return Container(
      padding: EdgeInsets.all(ringWidth * 0.6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor!, width: ringWidth),
      ),
      child: avatar,
    );
  }

  Widget _fallback() {
    if (userId == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.navy,
        child: Text(
          initialsFor(name),
          style: TextStyle(
            color: AppColors.white,
            fontSize: radius * 0.7,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: avatarGradientFor(userId),
      ),
      child: Text(
        initialsFor(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
