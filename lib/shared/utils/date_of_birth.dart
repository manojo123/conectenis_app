import 'package:intl/intl.dart';

int? ageFromDateOfBirth(DateTime? dateOfBirth) {
  if (dateOfBirth == null) return null;
  final today = DateTime.now();
  var age = today.year - dateOfBirth.year;
  final birthdayThisYear = DateTime(today.year, dateOfBirth.month, dateOfBirth.day);
  if (today.isBefore(birthdayThisYear)) age--;
  return age;
}

String formatDateOfBirth(DateTime? date) {
  if (date == null) return '—';
  return DateFormat('dd/MM/yyyy').format(date);
}

DateTime? parseDateOfBirth(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
