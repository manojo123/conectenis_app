import 'dart:async';

import 'package:flutter/foundation.dart';

class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 1500)});

  final Duration duration;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
