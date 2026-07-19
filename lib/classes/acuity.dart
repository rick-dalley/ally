import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

enum AcuityLevel { resuscitate, emergent, urgent, lessUrgent, notUrgent }

extension AcuityLevelLabel on AcuityLevel {
  String get label {
    switch (this) {
      case AcuityLevel.resuscitate:
        return "Resuscitate";
      case AcuityLevel.emergent:
        return "Emergent";
      case AcuityLevel.urgent:
        return "Urgent";
      case AcuityLevel.lessUrgent:
        return "Less Urgent";
      case AcuityLevel.notUrgent:
        return "Not Urgent";
    }
  }
}

extension AcuityLevelColor on AcuityLevel {
  Color get color {
    switch (this) {
      case AcuityLevel.resuscitate:
        return Color(0xFF043AC4);
      case AcuityLevel.emergent:
        return Color(0xFFFC900F);
      case AcuityLevel.urgent:
        return Color(0xFFFFEA00);
      case AcuityLevel.lessUrgent:
        return Color(0xFF23C402);
      case AcuityLevel.notUrgent:
        return Color(0xFFFFFFFF);
    }
  }
}

extension AcuityLevelBackgroundColor on AcuityLevel {
  Color get backgroundColor {
    switch (this) {
      case AcuityLevel.resuscitate:
        return AcuityLevel.resuscitate.color.withAlpha(96);
      case AcuityLevel.emergent:
        return AcuityLevel.emergent.color.withAlpha(96);
      case AcuityLevel.urgent:
        return AcuityLevel.urgent.color.withAlpha(96);
      case AcuityLevel.lessUrgent:
        return AcuityLevel.lessUrgent.color.withAlpha(96);
      case AcuityLevel.notUrgent:
        return AcuityLevel.notUrgent.color.withAlpha(96);
    }
  }
}

extension AcuityLevelIcon on AcuityLevel {
  IconData get iconData {
    switch (this) {
      case AcuityLevel.resuscitate:
        return Symbols.emergency;
      case AcuityLevel.emergent:
        return Symbols.circle_rounded;
      case AcuityLevel.urgent:
        return Symbols.circle_rounded;
      case AcuityLevel.lessUrgent:
        return Symbols.circle_rounded;
      case AcuityLevel.notUrgent:
        return Symbols.circle_rounded;
    }
  }
}

extension AcuityeLevelFontColor on AcuityLevel {
  Color get fontColor {
    switch (this) {
      case AcuityLevel.resuscitate:
        return AcuityLevel.resuscitate.color;
      case AcuityLevel.emergent:
        return AcuityLevel.emergent.color;
      case AcuityLevel.urgent:
        return Color(0xFF000000);
      case AcuityLevel.lessUrgent:
        return AcuityLevel.lessUrgent.color;
      case AcuityLevel.notUrgent:
        return Color(0xFF080808);
    }
  }
}

extension AcuityLevelFontStyle on AcuityLevel {
  TextStyle get textStyle {
    switch (this) {
      case AcuityLevel.resuscitate:
      case AcuityLevel.emergent:
      case AcuityLevel.urgent:
      case AcuityLevel.lessUrgent:
      case AcuityLevel.notUrgent:
        return TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: fontColor);
    }
  }
}

class Descriptor {
  final String name;
  final String description;

  const Descriptor({required this.description, required this.name});

  factory Descriptor.fromJson(dynamic json) {
    return Descriptor(name: json['name'] ?? "", description: json['description'] ?? "");
  }
}

class Acuity {
  final AcuityLevel level;
  final String statusName;
  final String clinicalPicture;
  final List<Descriptor> presentingWith;
  final List<Descriptor> secondaryModifiers;
  final int interventionWindow;

  Acuity({
    required this.level,
    required this.statusName,
    required this.clinicalPicture,
    required this.interventionWindow,
    required this.presentingWith,
    required this.secondaryModifiers,
  });

  // Using an initializer list is best practice for final fields in Dart
  factory Acuity.fromJson(dynamic json) {
    List<Descriptor> complaints = [];
    List<Descriptor> modifiers = [];
    dynamic rawComplaints = json["presenting_complaints"];
    dynamic rawModifiers = json["secondary_modifiers"];
    for (dynamic item in rawComplaints) {
      complaints.add(Descriptor.fromJson(item));
    }
    for (dynamic item in rawModifiers) {
      modifiers.add(Descriptor.fromJson(item));
    }
    return Acuity(
      level: AcuityLevel.values[json['level']],
      statusName: json['status'],
      clinicalPicture: json['clinical_picture'],
      interventionWindow: json['intervention_window'],
      presentingWith: complaints,
      secondaryModifiers: modifiers,
    );
  }
}

class AcuityFactory {
  // Private constructor
  AcuityFactory._();

  // The single instance
  static final AcuityFactory instance = AcuityFactory._();
  // Cached storage
  Map<AcuityLevel, Acuity> _acuities = {};

  // Initialization method (call this once at app startup)
  Future<void> initialize(String jsonPath) async {
    if (_acuities.isNotEmpty) return; // Prevent re-parsing

    final String jsonString = await rootBundle.loadString(jsonPath);
    final List<dynamic> jsonList = json.decode(jsonString);

    _acuities = {for (var item in jsonList) AcuityLevel.values[item['level']]: Acuity.fromJson(item)};
  }

  // 5. Easy access
  Acuity? getAcuity({required AcuityLevel level}) => _acuities[level];

  Map<AcuityLevel, Acuity> get allAcuities => Map.unmodifiable(_acuities);

  List<Acuity> getAllAcuitiesExcept(AcuityLevel currentLevel) {
    // We access .values to get the list of Acuity objects
    return _acuities.values.where((acuity) => acuity.level != currentLevel).toList();
  }
}
