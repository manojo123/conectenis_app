import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:conectenis_app/core/config/env.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

/// Native Google Sign-In; returns an **ID token** for [AuthRepository.socialLogin].
class GoogleAuthService {
  GoogleSignIn? _instance;

  GoogleSignIn get _googleSignIn {
    _instance ??= GoogleSignIn(
      scopes: const ['email', 'profile'],
      // Web OAuth client ID — must match Laravel `GOOGLE_CLIENT_ID` (token validation).
      serverClientId: Env.googleOAuthWebClientId.isNotEmpty
          ? Env.googleOAuthWebClientId
          : null,
      // iOS only: OAuth client ID type "iOS" from Google Cloud.
      clientId: Env.googleOAuthIosClientId.isNotEmpty ? Env.googleOAuthIosClientId : null,
    );
    return _instance!;
  }

  bool get isConfigured => Env.googleOAuthWebClientId.isNotEmpty;

  /// Returns Google ID token, or `null` if the user cancelled.
  Future<String?> signInForIdToken() async {
    if (!isConfigured) {
      throw StateError(
        'GOOGLE_OAUTH_WEB_CLIENT_ID is missing in .env. See docs/GOOGLE_SIGNIN.md',
      );
    }

    if (kIsWeb) {
      throw UnsupportedError('Google Sign-In is not configured for web in this app.');
    }

    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Google did not return an ID token. Check Android SHA-1 + OAuth clients in Google Cloud.',
      );
    }
    return idToken;
  }

  Future<void> signOut() async {
    if (_instance != null) {
      await _instance!.signOut();
    }
  }
}
