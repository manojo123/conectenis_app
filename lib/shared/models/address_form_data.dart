import 'package:conectenis_app/shared/models/user_profile.dart';
import 'package:conectenis_app/shared/utils/postal_code.dart';

class AddressFormData {
  const AddressFormData({
    this.postalCode = '',
    this.street = '',
    this.number = '',
    this.complement = '',
    this.neighborhood = '',
    this.city = '',
    this.state = '',
    this.country = 'BR',
    this.locationLocked = false,
  });

  final String postalCode;
  final String street;
  final String number;
  final String complement;
  final String neighborhood;
  final String city;
  final String state;
  final String country;
  final bool locationLocked;

  String get formattedPostalCode => formatPostalCode(postalCode);

  bool get hasValidPostalCode => normalizePostalCode(postalCode).length == 8;

  bool get isComplete =>
      hasValidPostalCode &&
      street.trim().isNotEmpty &&
      number.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      state.trim().isNotEmpty;

  String? validate({bool requireNumber = true}) {
    if (!hasValidPostalCode) return 'Informe um CEP válido (8 dígitos)';
    if (street.trim().isEmpty) return 'Informe o logradouro';
    if (requireNumber && number.trim().isEmpty) return 'Informe o número';
    if (city.trim().isEmpty || state.trim().isEmpty) {
      return 'Informe cidade e estado (use a busca por CEP)';
    }
    return null;
  }

  AddressFormData copyWith({
    String? postalCode,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
    String? country,
    bool? locationLocked,
  }) {
    return AddressFormData(
      postalCode: postalCode ?? this.postalCode,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      locationLocked: locationLocked ?? this.locationLocked,
    );
  }

  factory AddressFormData.fromUser(UserProfile user) {
    return AddressFormData(
      postalCode: user.postalCode ?? '',
      street: user.addressLine ?? '',
      number: user.addressNumber ?? '',
      complement: user.addressComplement ?? '',
      neighborhood: user.neighborhood ?? '',
      city: user.city ?? '',
      state: user.state ?? '',
      country: user.country ?? 'BR',
      locationLocked: (user.postalCode ?? '').isNotEmpty &&
          (user.city ?? '').isNotEmpty &&
          (user.state ?? '').isNotEmpty,
    );
  }

  UserProfile applyTo(UserProfile user) {
    return user.copyWith(
      postalCode: formattedPostalCode,
      addressLine: street.trim(),
      addressNumber: number.trim(),
      addressComplement: complement.trim().isEmpty ? null : complement.trim(),
      neighborhood: neighborhood.trim().isEmpty ? null : neighborhood.trim(),
      city: city.trim(),
      state: state.trim().toUpperCase(),
      country: country,
    );
  }

  Map<String, dynamic> toProfileJson() {
    return {
      'postal_code': formattedPostalCode,
      'address_line': street.trim(),
      'address_number': number.trim(),
      if (complement.trim().isNotEmpty) 'address_complement': complement.trim(),
      if (neighborhood.trim().isNotEmpty) 'neighborhood': neighborhood.trim(),
      'city': city.trim(),
      'state': state.trim().toUpperCase(),
      'country': country,
    };
  }
}
