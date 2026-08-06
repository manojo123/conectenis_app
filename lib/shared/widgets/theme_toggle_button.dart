import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/core/theme/theme_mode_provider.dart';
import 'package:conectenis_app/shared/widgets/frosted.dart';
import 'package:conectenis_app/shared/widgets/screen_header.dart';

/// Sun/moon circle that flips (and persists) the theme.
/// `frosted: true` is the floating map variant.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key, this.frosted = false, this.size = 40});

  final bool frosted;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final icon = isDark ? Symbols.light_mode_rounded : Symbols.dark_mode_rounded;
    void toggle() => ref.read(themeModeProvider.notifier).toggle();

    if (!frosted) {
      return CircleIconButton(
        icon: icon,
        iconSize: 20,
        size: size,
        color: t.muted,
        onTap: toggle,
        tooltip: isDark ? 'Tema claro' : 'Tema escuro',
      );
    }
    return Frosted(
      borderRadius: BorderRadius.circular(size / 2),
      border: Border.all(color: t.border),
      boxShadow: t.shadow,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: toggle,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 20, color: t.muted),
        ),
      ),
    );
  }
}
