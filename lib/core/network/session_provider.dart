import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Callback set by [AuthNotifier] when the API returns 401.
final onUnauthorizedProvider = StateProvider<void Function()?>((ref) => null);
