import 'dart:async';
import 'dart:ui';

import 'package:triage/classes/database_manager.dart';
import 'package:triage/classes/date_time_utilities.dart';
import 'package:triage/classes/patient_pain.dart';

import 'body_zone.dart';
import 'symptom_care_plan.dart';

class BodyMarker {
  final int? id; // null until it's been saved once
  final Offset offset;
  final PainLevel emoji;
  final AnatomyZoneMaps zoneMap;
  final String name; // the zone's plain name (e.g. "right hand") — persisted as zone_name
  final String medicalName; // the zone's latin name — derived from a Zone lookup, not persisted
  final BodyMarkerGroup group;
  DetailedPainLevel? severity;
  Frequency? frequency;
  PainType? nature;
  SymptomCarePlan? carePlan;
  String? descriptions;
  String? improvesWhen;
  String? worsensWhen;
  String? interventionsTried;
  final int recorded;
  bool resolved;
  DateTime? resolvedAt;
  DateTime? lastCheckedAt;

  BodyMarker({
    this.id,
    required this.offset,
    required this.emoji,
    required this.name,
    required this.medicalName,
    required this.zoneMap,
    required this.group,
    this.descriptions,
    this.severity,
    this.frequency,
    this.nature,
    this.carePlan,
    this.improvesWhen,
    this.worsensWhen,
    this.interventionsTried,
    int? recorded,
    this.resolved = false,
    this.resolvedAt,
    this.lastCheckedAt,
  }) : recorded = recorded ?? DTUtilities.now();

  factory BodyMarker.fromOffset(
    Offset offset,
    String name,
    String medicalName,
    AnatomyZoneMaps zoneMap,
    BodyMarkerGroup markerGroup,
  ) {
    return BodyMarker(
      offset: offset,
      emoji: PainLevel.severe,
      name: name,
      medicalName: medicalName,
      zoneMap: zoneMap,
      group: markerGroup,
    );
  }

  // The `markers` table stores zone_map + zone_name (there's no fixed, ordered list of
  // every Zone to index into — zones are loaded per body-part map from touch_points.json)
  // — so the actual Zone (and its latin name) is re-found from the already-loaded touch
  // image data at read time, rather than stored redundantly.
  factory BodyMarker.fromRow(Map<String, dynamic> row) {
    final AnatomyZoneMaps zoneMap = AnatomyZoneMaps.values[row['zone_map'] as int];
    final String zoneName = row['zone_name'] as String;
    final List<Zone> zones = TouchImageFactory.instance.getTouchImage(selection: zoneMap)?.zones ?? const [];
    String medicalName = '';
    for (final zone in zones) {
      if (zone.name == zoneName) {
        medicalName = zone.latin;
        break;
      }
    }

    final int? severityIndex = row['severity'] as int?;
    final int? frequencyIndex = row['frequency'] as int?;
    final int? natureIndex = row['nature'] as int?;
    final String? carePlanName = row['care_plan'] as String?;

    return BodyMarker(
      id: row['id'] as int?,
      offset: Offset((row['dx'] as num).toDouble(), (row['dy'] as num).toDouble()),
      name: zoneName,
      medicalName: medicalName,
      zoneMap: zoneMap,
      group: BodyMarkerGroup.values[row['marker_group'] as int],
      emoji: PainLevel.values[row['emoji'] as int],
      severity: severityIndex != null ? DetailedPainLevel.values[severityIndex] : null,
      frequency: frequencyIndex != null ? Frequency.values[frequencyIndex] : null,
      nature: natureIndex != null ? PainType.values[natureIndex] : null,
      carePlan: carePlanName != null ? SymptomCarePlan.values.byName(carePlanName) : null,
      descriptions: row['descriptions'] as String?,
      improvesWhen: row['improves_when'] as String?,
      worsensWhen: row['worsens_when'] as String?,
      interventionsTried: row['interventions_tried'] as String?,
      recorded: row['recorded'] as int,
      resolved: (row['resolved'] as int? ?? 0) == 1,
      resolvedAt: row['resolved_at'] != null ? DateTime.tryParse(row['resolved_at'] as String) : null,
      lastCheckedAt: row['last_checked_at'] != null ? DateTime.tryParse(row['last_checked_at'] as String) : null,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'dx': offset.dx,
      'dy': offset.dy,
      'zone_map': zoneMap.index,
      'zone_name': name,
      'marker_group': group.index,
      'emoji': emoji.index,
      'severity': severity?.index,
      'frequency': frequency?.index,
      'nature': nature?.index,
      'care_plan': carePlan?.name,
      'descriptions': descriptions,
      'improves_when': improvesWhen,
      'worsens_when': worsensWhen,
      'interventions_tried': interventionsTried,
      'recorded': recorded,
      'resolved': resolved ? 1 : 0,
      'resolved_at': resolvedAt?.toIso8601String(),
      'last_checked_at': lastCheckedAt?.toIso8601String(),
    };
  }

  Duration get age => DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(recorded * 1000));

  Future<int> save({required String patientUuid}) {
    return DatabaseManager().insertBodyMarker(patientUuid, toRow());
  }
}
