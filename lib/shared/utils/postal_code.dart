String normalizePostalCode(String input) {
  return input.replaceAll(RegExp(r'\D'), '');
}

String formatPostalCode(String input) {
  final digits = normalizePostalCode(input);
  if (digits.length <= 5) return digits;
  return '${digits.substring(0, 5)}-${digits.substring(5)}';
}

bool isValidPostalCode(String input) => normalizePostalCode(input).length == 8;
