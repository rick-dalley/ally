import 'dart:convert';

// The receiving half of Progressor's discharge-report handoff — no shared backend, a
// physician sends the patient an email whose body carries an ally://import?data=...
// deep link. The payload is intentionally small (active orders/medications only, not
// the full clinical record) since deep-link URLs have practical length limits. Key
// names here must match Progressor's DischargeReportScreen._buildAllyImportLink()
// exactly — there's no shared package/type between the two apps for this payload.
class ImportedOrder {
  final String label;
  final String? directions;
  final String? frequency;

  const ImportedOrder({required this.label, this.directions, this.frequency});

  factory ImportedOrder.fromJson(Map<String, dynamic> json) {
    return ImportedOrder(
      label: json['label'] as String,
      directions: json['directions'] as String?,
      frequency: json['frequency'] as String?,
    );
  }
}

class ImportedMedication {
  final String name;
  final String? dose;
  final String? freq;

  const ImportedMedication({required this.name, this.dose, this.freq});

  factory ImportedMedication.fromJson(Map<String, dynamic> json) {
    return ImportedMedication(
      name: json['name'] as String,
      dose: json['dose'] as String?,
      freq: json['freq'] as String?,
    );
  }
}

class CarePlanImportPayload {
  final String patientName;
  final List<ImportedOrder> orders;
  final List<ImportedMedication> medications;

  const CarePlanImportPayload({required this.patientName, required this.orders, required this.medications});

  // Returns null rather than throwing — a malformed or truncated link (a copy-paste
  // mangled it, or a future payload version we don't understand yet) should fail quietly
  // into "couldn't read this care plan," not crash the app that just opened it.
  static CarePlanImportPayload? tryParse(Uri uri) {
    final String? encoded = uri.queryParameters['data'];
    if (encoded == null) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(utf8.decode(base64Url.decode(encoded))) as Map<String, dynamic>;
      final List<dynamic> orderList = json['orders'] as List<dynamic>? ?? [];
      final List<dynamic> medList = json['medications'] as List<dynamic>? ?? [];
      return CarePlanImportPayload(
        patientName: json['patientName'] as String? ?? 'Unknown Patient',
        orders: orderList.map((o) => ImportedOrder.fromJson(o as Map<String, dynamic>)).toList(),
        medications: medList.map((m) => ImportedMedication.fromJson(m as Map<String, dynamic>)).toList(),
      );
    } catch (_) {
      return null;
    }
  }
}
