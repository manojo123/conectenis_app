/// Human-readable NTRP category for dashboard display.
String ntrpCategoryLabel(double rating) {
  if (rating < 2.0) return 'Iniciante';
  if (rating < 3.0) return 'Principiante';
  if (rating < 4.0) return 'Intermediário';
  if (rating < 5.0) return 'Avançado';
  return 'Profissional';
}

String ntrpLevelDisplay(double rating) {
  return '${ntrpCategoryLabel(rating)} (${rating.toStringAsFixed(1)})';
}
