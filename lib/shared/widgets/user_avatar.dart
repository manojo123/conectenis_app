import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/shared/utils/media_url.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 20,
  });

  final String name;
  final String? avatarUrl;
  final double radius;

  ImageProvider? _imageProvider(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return CachedNetworkImageProvider(trimmed);
    }
    final file = File(trimmed);
    if (file.existsSync()) {
      return FileImage(file);
    }
    final resolved = resolveMediaUrl(trimmed);
    if (resolved.isNotEmpty) {
      return CachedNetworkImageProvider(resolved);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final provider = _imageProvider(avatarUrl);

    if (provider != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.navy,
        backgroundImage: provider,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy,
      child: Text(initial, style: TextStyle(color: Colors.white, fontSize: radius * 0.9)),
    );
  }
}
