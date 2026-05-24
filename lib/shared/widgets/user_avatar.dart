import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.navy,
        backgroundImage: NetworkImage(url),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy,
      child: Text(initial, style: TextStyle(color: Colors.white, fontSize: radius * 0.9)),
    );
  }
}
