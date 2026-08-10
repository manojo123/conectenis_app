import 'package:conectenis_app/shared/models/json_parsers.dart';

class City {
  const City({required this.id, required this.name, required this.state});

  final int id;
  final String name;
  final String state;

  String get label => '$name, $state';

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: parseJsonInt(json['id']),
      name: json['name'] as String? ?? '',
      state: json['state'] as String? ?? '',
    );
  }
}
