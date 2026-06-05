import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';

enum AppSnackType { success, warning, danger, info }

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackType type = AppSnackType.info,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        behavior: SnackBarBehavior.floating,
        content: _SnackContent(message: message, type: type),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackType.success);

  static void showWarning(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackType.warning);

  static void showDanger(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackType.danger);
}

class _SnackContent extends StatelessWidget {
  const _SnackContent({required this.message, required this.type});

  final String message;
  final AppSnackType type;

  Color get _accent => switch (type) {
        AppSnackType.success => const Color(0xFF4ADE80),
        AppSnackType.warning => const Color(0xFFFACC15),
        AppSnackType.danger => AppColors.error,
        AppSnackType.info => AppColors.lime,
      };

  IconData get _icon => switch (type) {
        AppSnackType.success => Icons.check_circle_outline,
        AppSnackType.warning => Icons.warning_amber_outlined,
        AppSnackType.danger => Icons.error_outline,
        AppSnackType.info => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.9;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(_icon, color: _accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: _accent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
