import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/app/router.dart';

/// Listens for `conectenis://reset-password?token=...&email=...` and navigates.
class DeepLinkListener extends ConsumerStatefulWidget {
  const DeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<DeepLinkListener> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleUri);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInitialLink());
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleInitialLink() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      _handleUri(uri);
    }
  }

  void _handleUri(Uri uri) {
    final isResetLink = uri.host == 'reset-password' ||
        uri.path.contains('reset-password');
    if (!isResetLink) return;

    final token = uri.queryParameters['token'];
    final email = uri.queryParameters['email'];
    if (token == null || email == null) return;

    ref.read(routerProvider).go(
          '/reset-password?token=${Uri.encodeComponent(token)}&email=${Uri.encodeComponent(email)}',
        );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
