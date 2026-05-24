double parseJsonDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int parseJsonInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

List<Map<String, dynamic>> parseJsonList(dynamic data) {
  if (data is List) {
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  if (data is Map<String, dynamic>) {
    final nested = data['data'];
    if (nested is List) {
      return nested.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }
  return [];
}

Map<String, dynamic> parseJsonObject(dynamic data) {
  if (data is Map<String, dynamic>) {
    final nested = data['data'];
    if (nested is Map) return Map<String, dynamic>.from(nested);
    return data;
  }
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final nested = map['data'];
    if (nested is Map) return Map<String, dynamic>.from(nested);
    return map;
  }
  throw const FormatException('Expected JSON object');
}
