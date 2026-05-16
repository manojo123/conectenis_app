import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';

/// Local profile extension until Laravel exposes PUT /user/profile.
class ProfileStorage {
  ProfileStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'local_profile';

  Future<UserProfile?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> write(UserProfile profile) =>
      _storage.write(key: _key, value: jsonEncode(profile.toJson()));

  Future<void> clear() => _storage.delete(key: _key);
}
