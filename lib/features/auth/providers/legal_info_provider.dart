import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conectenis_app/core/config/env.dart';
import 'package:conectenis_app/core/network/dio_provider.dart';

class LegalInfo {
  const LegalInfo({
    required this.termsUrl,
    required this.privacyUrl,
    required this.version,
  });

  final String termsUrl;
  final String privacyUrl;
  final String version;

  factory LegalInfo.fromEnv() => LegalInfo(
        termsUrl: Env.legalTermsUrl,
        privacyUrl: Env.legalPrivacyUrl,
        version: Env.legalVersion,
      );

  factory LegalInfo.fromJson(Map<String, dynamic> json) => LegalInfo(
        termsUrl: json['terms_url'] as String? ?? Env.legalTermsUrl,
        privacyUrl: json['privacy_url'] as String? ?? Env.legalPrivacyUrl,
        version: json['version'] as String? ?? Env.legalVersion,
      );
}

final legalInfoProvider = FutureProvider<LegalInfo>((ref) async {
  if (Env.useMockApi) return LegalInfo.fromEnv();
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<Map<String, dynamic>>('/legal');
    return LegalInfo.fromJson(response.data ?? {});
  } catch (_) {
    return LegalInfo.fromEnv();
  }
});
