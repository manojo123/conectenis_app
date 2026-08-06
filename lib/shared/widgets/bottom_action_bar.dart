import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/shared/widgets/frosted.dart';

/// Pinned footer for primary actions: top border + frosted translucent bg.
/// Use in the `Scaffold.bottomNavigationBar` slot so the keyboard lifts it.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child, this.hint});

  final Widget child;

  /// Small muted helper line under the actions ("Escolha o adversário…").
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Frosted(
      border: Border(top: BorderSide(color: t.border)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              if (hint != null) ...[
                const SizedBox(height: 7),
                Text(
                  hint!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: t.disabled),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
