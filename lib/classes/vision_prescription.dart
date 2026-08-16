import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/widgets.dart' show IconData;

// Glasses and contacts are the same real-world object — numbers from an eye exam —
// differing only in which fields apply (contacts add base curve/diameter; the
// sphere/cylinder/axis/add core is shared). One table, one type flag, not two.
enum VisionPrescriptionType {
  glasses,
  contacts;

  String get label {
    switch (this) {
      case VisionPrescriptionType.glasses:
        return "Glasses";
      case VisionPrescriptionType.contacts:
        return "Contacts";
    }
  }

  IconData get icon {
    switch (this) {
      case VisionPrescriptionType.glasses:
        return Symbols.eyeglasses;
      case VisionPrescriptionType.contacts:
        return Symbols.visibility;
    }
  }
}

// A vision prescription is a static credential, not a tracked/dosed thing — the whole
// point is to be pulled up and shown to someone else in a few seconds (an optician, a
// retailer), not edited often. Kept deliberately separate from the medication wizard,
// which is a completely different flow with completely different data (dose, frequency,
// reminders, shape, color — none of which apply here).
class VisionPrescription {
  final int? id;
  final String patientUuid;
  final String? providerUuid; // the optometrist who issued it
  final VisionPrescriptionType type;

  // Right eye (OD) / left eye (OS) — standard optometry shorthand for the DB columns;
  // UI-facing labels use plain "Right Eye"/"Left Eye" instead.
  final double? odSphere;
  final double? odCylinder;
  final int? odAxis;
  final double? odAdd;
  final double? osSphere;
  final double? osCylinder;
  final int? osAxis;
  final double? osAdd;

  final double? pd; // pupillary distance
  final double? baseCurve; // contacts only
  final double? diameter; // contacts only

  final DateTime? issuedDate;
  final DateTime? expiryDate;
  final String notes;

  const VisionPrescription({
    this.id,
    required this.patientUuid,
    this.providerUuid,
    required this.type,
    this.odSphere,
    this.odCylinder,
    this.odAxis,
    this.odAdd,
    this.osSphere,
    this.osCylinder,
    this.osAxis,
    this.osAdd,
    this.pd,
    this.baseCurve,
    this.diameter,
    this.issuedDate,
    this.expiryDate,
    this.notes = "",
  });

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());

  factory VisionPrescription.fromRow(Map<String, dynamic> row) {
    return VisionPrescription(
      id: row['id'] as int?,
      patientUuid: row['patient_uuid'] as String,
      providerUuid: row['provider_uuid'] as String?,
      type: VisionPrescriptionType.values[row['type'] as int? ?? 0],
      odSphere: row['od_sphere'] as double?,
      odCylinder: row['od_cylinder'] as double?,
      odAxis: row['od_axis'] as int?,
      odAdd: row['od_add'] as double?,
      osSphere: row['os_sphere'] as double?,
      osCylinder: row['os_cylinder'] as double?,
      osAxis: row['os_axis'] as int?,
      osAdd: row['os_add'] as double?,
      pd: row['pd'] as double?,
      baseCurve: row['base_curve'] as double?,
      diameter: row['diameter'] as double?,
      issuedDate: row['issued_date'] != null ? DateTime.tryParse(row['issued_date'] as String) : null,
      expiryDate: row['expiry_date'] != null ? DateTime.tryParse(row['expiry_date'] as String) : null,
      notes: row['notes'] as String? ?? "",
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'patient_uuid': patientUuid,
      'provider_uuid': providerUuid,
      'type': type.index,
      'od_sphere': odSphere,
      'od_cylinder': odCylinder,
      'od_axis': odAxis,
      'od_add': odAdd,
      'os_sphere': osSphere,
      'os_cylinder': osCylinder,
      'os_axis': osAxis,
      'os_add': osAdd,
      'pd': pd,
      'base_curve': baseCurve,
      'diameter': diameter,
      'issued_date': issuedDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'notes': notes,
    };
  }
}
