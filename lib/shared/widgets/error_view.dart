import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/shared/widgets/lime_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: t.tintErr,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Symbols.error_rounded, size: 32, color: t.error),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: t.muted, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              LimeButton(label: 'Tentar novamente', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
