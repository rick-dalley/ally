import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:triage/classes/database_manager.dart';
import 'package:triage/classes/date_time_utilities.dart';
import 'package:triage/classes/patient_pain.dart';

import 'body_zone.dart';

class BodyMarker {
  final Offset offset;
  final PainLevel emoji;
  final AnatomyZoneMaps zoneMap;
  final String name;
  final String medicalName;
  final BodyMarkerGroup group;
  DetailedPainLevel? severity;
  Frequency? frequency;
  PainType? nature;
  String? descriptions;
  String? improvesWhen;
  String? worsensWhen;
  String? interventionsTried;
  int? recorded = DTUtilities.now();

  BodyMarker({
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
    this.improvesWhen,
    this.worsensWhen,
    this.interventionsTried,
    this.recorded,
  });

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
  factory BodyMarker.fromJson(Map<String, dynamic> item) {
    int severityIndex = item["severity"];
    int emojiIndex = item["emoji"];
    int frequencyIndex = item["frequency"];
    int natureIndex = item["nature"];
    AnatomyZoneMaps zoneMap = AnatomyZoneMaps.values[item["map"]];
    Zone zoneFromJson = Zone.fromJson(item["zone"], zoneMap);
    double dx = item["dx"];
    double dy = item["dy"];
    String descriptionChips = item["description"];
    String improvesWhenChips = item["improves_when"];
    String worsensWhenChips = item["worsens_when"];
    String interventionsTriedChips = item["interventions_tried"];

    return BodyMarker(
      offset: Offset(dx, dy),
      name: zoneFromJson.name,
      medicalName: zoneFromJson.latin,
      descriptions: descriptionChips,
      severity: DetailedPainLevel.values[severityIndex],
      emoji: PainLevel.values[emojiIndex],
      frequency: Frequency.values[frequencyIndex],
      nature: PainType.values[natureIndex],
      improvesWhen: improvesWhenChips,
      worsensWhen: worsensWhenChips,
      interventionsTried: interventionsTriedChips,
      recorded: item["recorded"],
      group: BodyMarkerGroup.values[item['group']],
      zoneMap: zoneFromJson.map,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "dx": offset.dx,
      "dy": offset.dy,
      "name": name,
      "medical_name": medicalName,
      "emoji": emoji.index,
      "severity": severity?.index,
      "frequency": frequency?.index,
      "nature": nature?.index,
      "improves_when": improvesWhen,
      "worsens_when": worsensWhen,
      "interventions_tried": interventionsTried,
      "descriptions": descriptions,
      "recorded": recorded,
      "zone": zoneMap,
      "group": group,
    };
  }

  Future<void> save({required String patientUuid, required BodyMarker marker}) async {
    DatabaseManager().insertBodyMarker(patientUuid, marker.toJson());
  }
}

class MarkerFactory {
  // Singleton pattern for clean access across your app
  static final MarkerFactory instance = MarkerFactory._internal();
  factory MarkerFactory() => instance;
  MarkerFactory._internal();

  Future<List<BodyMarker>> getMarkersForPatient(String patientUuid) async {
    // 1. Fetch raw data from the actual database
    final List<Map<String, dynamic>> rawData = await DatabaseManager().getMarkersForPatient(patientUuid);

    // 2. Hydrate: Convert JSON strings back to lists, then to BodyMarker objects
    return rawData.map((item) {
      // Create a mutable copy to perform decoding
      Map<String, dynamic> decodedItem = Map<String, dynamic>.from(item);

      // Decode the stored JSON strings back into dynamic lists
      decodedItem['description'] = jsonDecode(decodedItem['descriptions'] ?? '[]');
      decodedItem['improves_when'] = jsonDecode(decodedItem['improves_when'] ?? '[]');
      decodedItem['worsens_when'] = jsonDecode(decodedItem['worsens_when'] ?? '[]');
      decodedItem['interventions_tried'] = jsonDecode(decodedItem['interventions_tried'] ?? '[]');

      return BodyMarker.fromJson(decodedItem);
    }).toList();
  }

  Future<void> saveMarkersForPatient(String patientUuid, List<BodyMarker> markers) async {
    // Convert BodyMarkers to the database-friendly Map format
    List<Map<String, dynamic>> rows = markers.map((marker) {
      Map<String, dynamic> row = marker.toJson();
      row['patient_uuid'] = patientUuid;

      // Handle the serialization logic here, NOT in the database manager
      row['descriptions'] = jsonEncode(row['descriptions'] ?? []);
      row['improves_when'] = jsonEncode(row['improves_when'] ?? []);
      row['worsens_when'] = jsonEncode(row['worsens_when'] ?? []);
      row['interventions_tried'] = jsonEncode(row['interventions_tried'] ?? []);

      return row;
    }).toList();

    // The database manager just sees raw data, not 'Markers'
    await DatabaseManager().insertMarkersBatch('body_markers', rows);
  }
}
