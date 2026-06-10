import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/app/deep_link_listener.dart';
import 'package:conectenis_app/app/router.dart';
import 'package:conectenis_app/core/theme/app_theme.dart';
import 'package:conectenis_app/core/theme/theme_mode_provider.dart';

class ConecTenisApp extends ConsumerWidget {
  const ConecTenisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return DeepLinkListener(
      child: MaterialApp.router(
        title: 'ConecTenis',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
