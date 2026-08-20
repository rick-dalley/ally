import 'package:ally/classes/country_codes.dart';

import '../classes/locatable.dart';

class Address implements Locatable {
  final String? locationName;
  @override
  final String street;
  @override
  final String city;
  @override
  final String code;
  @override
  final String country;
  @override
  final String countryIso;
  @override
  final String provOrState;
  const Address({
    required this.city,
    required this.street,
    required this.country,
    required this.code,
    required this.provOrState,
    required this.countryIso,
    this.locationName,
  });
  factory Address.fromMap(Map<String, dynamic> item) {
    String streetRaw = item['street'];
    String cityRaw = item['city'];
    String provOrStateRaw = item['pr_st'];
    String codeRaw = item['code'];
    String countryRaw = item['country'];
    String? countryIsoRaw = item['country_iso'] ?? toCountryCode[countryRaw] != null
        ? toCountryCode[countryRaw]?.isoA2
        : '';
    String iso = countryIsoRaw ?? 'US';
    return Address(
      city: cityRaw,
      street: streetRaw,
      country: countryRaw,
      code: codeRaw,
      provOrState: provOrStateRaw,
      countryIso: iso,
    );
  }
  String get full {
    return '$street, $city, $provOrState, $country, $code';
  }

  String get fullFormatted {
    return '$street,\n $city, $provOrState,\n $country,\n $code';
  }

  static Address? copy(Address? address) {
    if (address != null) {
      return Address(
        city: address.city,
        street: address.street,
        country: address.country,
        code: address.code,
        provOrState: address.provOrState,
        countryIso: address.countryIso,
      );
    }
    return null;
  }
}
