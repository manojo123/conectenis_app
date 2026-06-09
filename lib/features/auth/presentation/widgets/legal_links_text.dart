import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalLinksText extends StatelessWidget {
  const LegalLinksText({
    super.key,
    required this.termsUrl,
    required this.privacyUrl,
    this.prefix = 'Li e aceito os ',
  });

  final String termsUrl;
  final String privacyUrl;
  final String prefix;

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: 'Termos de Uso',
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = () => _open(termsUrl),
          ),
          const TextSpan(text: ' e a '),
          TextSpan(
            text: 'Política de Privacidade',
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = () => _open(privacyUrl),
          ),
        ],
      ),
    );
  }
}
