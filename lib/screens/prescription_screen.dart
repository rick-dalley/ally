import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_theme_constants.dart';
import 'package:triage/screens/add_medication_wizard.dart';
import 'package:triage/widgets/carbon_style_button.dart';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/medication_services.dart';
import '../classes/patient.dart';
import '../widgets/medication_card.dart';

class PrescriptionScreen extends StatefulWidget {
  final Patient patient;

  const PrescriptionScreen({super.key, required this.patient});

  @override
  State<PrescriptionScreen> createState() => PrescriptionScreenState();
}

class PrescriptionScreenState extends State<PrescriptionScreen> {
  // Mocking the current baseline list
  bool hasContraIndications = false;
  final bool hasAcceptedIndications = false;
  Map<String, Medication> medications = {};
  late List<InteractionConflict> currentConflicts = []; // The source of truth for the UI
  bool audited = false;

  // These are derived flags
  final bool _hasPrecautions = false; // Set this based on your separate logic
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final frequencyController = TextEditingController();
  late int dataSheetCount = 0;

  @override
  void initState() {
    super.initState();
    loadMedsForPatient();
  }

  void handleConflictsFound(List<InteractionConflict> conflicts) {
    setState(() {
      currentConflicts = conflicts;
    });
  }

  Future<void> loadMedsForPatient() async {
    try {
      List<Map<String, dynamic>> prescription = await MedicationService.getPrescriptionFor(widget.patient.patientUuid);

      final tempMap = <String, Medication>{};
      for (Map<String, dynamic> medicationData in prescription) {
        Medication medication = Medication.fromMap(medicationData, widget.patient.patientUuid);
        tempMap[medication.id] = medication;
      }

      setState(() {
        medications = tempMap;
      });
    } catch (e) {
      debugPrint("Error loading medications from DB: $e");
    }
  }

  Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void refreshMedInUI(String medId, String setId) {
    setState(() {
      if (medications[medId] != null) {
        medications[medId]!.setId = setId;
        medications[medId]!.isSyncing = false;
      }
    });
  }

  void stopSyncSpinner(String medId) {
    setState(() {
      medications[medId]!.isSyncing = false;
    });
  }

  void showAddMedicationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Crucial to keep keyboard from covering fields
      useSafeArea: true, // This adds the padding for the notch and system bars
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),

      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // Moves with keyboard
          left: 24,
          right: 24,
          top: 24,
        ),
        child: AddMedicationWizard(
          patientUuid: widget.patient.patientUuid,
          nameController: nameController,
          dosageController: dosageController,
          frequencyController: frequencyController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = medications.entries.toList();
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // The Floating Action Button replaces the top form
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          key: Key("FAB_NewPrescription"),
          heroTag: "prescription_screen",
          onPressed: () => showAddMedicationSheet(),
          child: const Icon(Symbols.add, size: 32),
        ),
      ),
      body: Column(
        children: [
          InteractionsWidget(medications: medications, onConflictsFound: handleConflictsFound),
          // CURRENT LIST: The Baseline
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final med = entries[index].value;
                // We swap the old ListTile for our new smart card
                return MedicationCard(
                  key: Key(med.id),
                  interactions: currentConflicts,
                  medication: med,
                  index: index,
                  onDelete: () async {
                    // 1. Remove from the local database
                    await DatabaseManager().deleteMedication(med.id);

                    // 2. Remove from the UI state
                    setState(() {
                      medications.remove(med);
                    });
                  },
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      med.hasLocalDataSheet = true;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyAudit {
  static const String severityMajor = "MAJOR / CONTRAINDICATED";
  static const String severityModerate = "MODERATE";

  // Using ATC Class IDs for robust logic
  static Map<String, dynamic>? run(List<String> classIds) {
    // 1. SSRI (N06AB) + Opioid (N02AX) -> Serotonin Syndrome
    if (classIds.contains("N06AB") && classIds.contains("N02AX")) {
      return {
        "severity": severityMajor,
        "warning":
            "Risk of Serotonin Syndrome: Potentially life-threatening interaction between SSRI and specific opioids.",
        "color": Colors.red,
      };
    }

    // 2. Sertraline (N06AB) + Quetiapine (N05AH) -> QT Prolongation
    if (classIds.contains("N06AB") && classIds.contains("N05AH")) {
      return {
        "severity": severityModerate,
        "warning":
            "Risk of QT Prolongation: Both medications can affect heart rhythm. Monitoring (ECG) may be required.",
        "color": Colors.orange,
      };
    }

    return null;
  }
}

enum BannerType { acknowledged, advisory, critical, none, unknown }

class BannerData {
  final Color color;
  final String message;
  final IconData icon;

  const BannerData({required this.color, required this.message, required this.icon});

  Color get bannerColor => AppTheme.surfaceColor;
}

class InteractionsWidget extends StatefulWidget {
  final Map<String, Medication> medications;
  final Function(List<InteractionConflict>) onConflictsFound;
  const InteractionsWidget({super.key, required this.medications, required this.onConflictsFound});

  @override
  State<StatefulWidget> createState() => InteractionsWidgetState();
}

class InteractionsWidgetState extends State<InteractionsWidget> {
  late Map<String, Medication> medications;
  late bool audited;
  late bool hasContraIndications;
  late bool hasPrecautions;
  late bool hasAcceptedIndications;
  late List<InteractionConflict> conflicts;

  void runSafetyAudit() async {
    // Guard clause: Don't spend processing cycles if the list hasn't loaded ye

    setState(() {
      conflicts.clear();
    });

    for (Medication medicationA in medications.values) {
      // 1. Defend against null values coming from SQLite mapping
      final String nameA = medicationA.name;
      medicationA.hasInteractions = false;

      if (nameA.isEmpty) continue; // 2. Skip audit logic if it has no FDA set_id synced yet

      for (var medicationB in medications.values) {
        final String nameB = medicationB.name;
        if (nameB.isEmpty || nameA == nameB) continue;
        final String? interaction = await DatabaseManager().getInteractions(nameA, nameB);

        if (interaction != null) {
          conflicts.add(
            InteractionConflict(
              primaryMedName: medicationA.name,
              conflictingMedName: medicationB.name,
              interaction: interaction,
            ),
          );

          setState(() => medicationA.hasInteractions = true);
        }
      }
    }
    if (mounted) {
      setState(() {
        audited = true;
        hasContraIndications = conflicts.isNotEmpty;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    conflicts = [];
    medications = widget.medications;
    audited = false;
    hasContraIndications = false;
    hasPrecautions = false;
    hasAcceptedIndications = false;
    runSafetyAudit();
  }

  @override
  void didUpdateWidget(covariant InteractionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      medications = widget.medications;
    });
  }

  final Map<BannerType, BannerData> banners = {
    BannerType.critical: const BannerData(
      color: Color(0xFFD32F2F),
      message: "CRITICAL: Contraindication Detected",
      icon: Symbols.join_inner,
    ),
    BannerType.advisory: const BannerData(
      color: Color(0xFFFF8F00),
      message: "ADVISORY: Precautions Required",
      icon: Symbols.warning_amber_rounded,
    ),
    BannerType.acknowledged: const BannerData(
      color: Color(0xFF673AB7),
      message: "All Risks Acknowledged & Accepted",
      icon: Icons.check_circle_outline,
    ),
    BannerType.none: BannerData(
      color: AppTheme.primaryColor,
      message: "No Interactions Detected",
      icon: Symbols.verified,
    ),
    BannerType.unknown: BannerData(
      color: AppTheme.tertiaryColor,
      message: "Not yet checked",
      icon: Symbols.unknown_document,
    ),
  };

  @override
  Widget build(BuildContext context) {
    BannerData bannerData;
    // Example Logic check:
    if (!audited) {
      bannerData = banners[BannerType.unknown]!;
    } else if (hasContraIndications) {
      bannerData = banners[BannerType.critical]!;
    } else if (hasPrecautions) {
      bannerData = banners[BannerType.advisory]!;
    } else if (hasAcceptedIndications) {
      bannerData = banners[BannerType.acknowledged]!;
    } else {
      bannerData = banners[BannerType.none]!;
    }
    return Container(
      width: double.infinity,
      color: AppTheme.lightTheme.canvasColor,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(bannerData.icon, color: bannerData.color, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(bannerData.message, style: CarbonTheme.carbonLabelTextStyle)),
          Expanded(
            child: CarbonButton(
              label: "Check",
              onPressed: runSafetyAudit,
              icon: Symbols.fact_check,
              style: CarbonButtonStyle.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}
