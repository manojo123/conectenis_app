import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/shared/utils/media_url.dart';

void showFullScreenImage(BuildContext context, {String? imageUrl, String? heroTag}) {
  final resolved = resolveMediaUrl(imageUrl);
  if (resolved.isEmpty) return;

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => _FullScreenImagePage(imageUrl: resolved, heroTag: heroTag),
    ),
  );
}

class _FullScreenImagePage extends StatelessWidget {
  const _FullScreenImagePage({required this.imageUrl, this.heroTag});

  final String imageUrl;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final image = InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) =>
              Icon(Icons.broken_image, size: 64, color: AppColors.white.withValues(alpha: 0.54)),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          heroTag != null ? Hero(tag: heroTag!, child: image) : image,
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
