import 'dart:convert';

import 'package:flutter/services.dart';

class FrequencyCode {
  final String code;
  final String latinRoot;
  final String english;

  FrequencyCode({required this.code, required this.latinRoot, required this.english});

  factory FrequencyCode.fromJson(Map<String, dynamic> json) {
    return FrequencyCode(
      code: json['Code'] as String,
      latinRoot: json['LatinRoot'] as String,
      english: json['English'] as String,
    );
  }
}

class FrequencyCodeService {
  static List<FrequencyCode>? _cachedCodes;

  static Future<List<FrequencyCode>> getCodes() async {
    if (_cachedCodes != null) return _cachedCodes!;

    final String response = await rootBundle.loadString('assets/codes/frequency_codes.json');
    final List<dynamic> data = json.decode(response);

    _cachedCodes = data.map((item) => FrequencyCode.fromJson(item)).toList();
    return _cachedCodes!;
  }
}
