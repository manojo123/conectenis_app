class AddressLookup {
  const AddressLookup({
    required this.postalCode,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
    this.stateName,
    this.country = 'BR',
    this.complementHint,
    this.ibge,
    this.ddd,
  });

  final String postalCode;
  final String street;
  final String neighborhood;
  final String city;
  final String state;
  final String? stateName;
  final String country;
  final String? complementHint;
  final String? ibge;
  final String? ddd;

  factory AddressLookup.fromJson(Map<String, dynamic> json) {
    return AddressLookup(
      postalCode: json['postal_code'] as String? ?? '',
      street: json['street'] as String? ?? '',
      neighborhood: json['neighborhood'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      stateName: json['state_name'] as String?,
      country: json['country'] as String? ?? 'BR',
      complementHint: json['complement_hint'] as String?,
      ibge: json['ibge'] as String?,
      ddd: json['ddd'] as String?,
    );
  }
}
