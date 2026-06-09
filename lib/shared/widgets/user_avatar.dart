import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/shared/utils/gravatar.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.email,
    this.hasCustomAvatar = false,
    this.radius = 20,
  });

  final String name;
  final String? avatarUrl;
  final String? email;
  final bool hasCustomAvatar;
  final double radius;

  String get _initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

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

  Widget _fallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy,
      child: Text(
        _initial,
        style: TextStyle(color: Colors.white, fontSize: radius * 0.9),
      ),
    );
  }
}
