import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/screens/add_medication_wizard.dart';
import 'package:triage/widgets/carbon_style_button.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/medication_services.dart';
import '../classes/patient.dart';
import '../widgets/medication_card.dart';

enum BannerType { acknowledged, advisory, critical, none, unknown }

class BannerData {
  final Color color;
  final String message;
  final IconData icon;

  const BannerData({required this.color, required this.message, required this.icon});

  Color get bannerColor => AppTheme.surfaceColor;
}

// Fixed map syntax using standard key: value pairs
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
    color: AppTheme.lightTheme.primaryColorDark,
    message: "No Interactions Detected",
    icon: Symbols.verified,
  ),
  BannerType.unknown: BannerData(
    color: AppColors.grey.all[3],
    message: "Not yet checked",
    icon: Symbols.unknown_document,
  ),
};

class PrescriptionScreen extends StatefulWidget {
  final Patient patient;

  const PrescriptionScreen({super.key, required this.patient});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  // Mocking the current baseline list
  bool _isLoading = false;
  bool _hasContraIndications = false;
  final bool _acceptedIndications = false;
  List<Map<String, dynamic>> _meds = [];
  final List<InteractionConflict> _currentConflicts = []; // The source of truth for the UI
  bool _auditRun = false;

  // These are derived flags
  final bool _hasPrecautions = false; // Set this based on your separate logic
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final frequencyController = TextEditingController();
  late int _dataSheetCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMedsForPatient();
    _runSafetyAudit();
  }

  int _countDataSheets() {
    int count = 0;
    if (_meds.isNotEmpty) {
      for (dynamic m in _meds) {
        if (m["has_local_datasheet"] > 0) {
          count++;
        }
      }
    }
    return count;
  }

  Future<void> _loadMedsForPatient() async {
    try {
      // 1. Call the database instead of the JSON asset
      final List<Map<String, dynamic>> dbMeds = await DatabaseManager().getMedicationsForPatient(
        widget.patient.patientUuid,
      );

      setState(() {
        // 2. We need to create a mutable copy because db results are read-only
        _meds = dbMeds.map((m) => Map<String, dynamic>.from(m)).toList();
        _runSafetyAudit();

        // 3. Inject your UI-specific state (Severity)
        for (var med in _meds) {
          med['severity'] = med['severity'] ?? 'Neutral';
        }
      });
    } catch (e) {
      debugPrint("Error loading medications from DB: $e");
    }
  }

  void _runSafetyAudit() async {
    _dataSheetCount = _countDataSheets();
    // Guard clause: Don't spend processing cycles if the list hasn't loaded yet
    if (_meds.isEmpty || _dataSheetCount < 2) return;

    setState(() {
      _isLoading = true;
      _currentConflicts.clear();
    });

    for (var primaryMed in _meds) {
      // 1. Defend against null values coming from SQLite mapping
      final String nameA = primaryMed['name'] ?? '';
      primaryMed['has_interaction'] = 0;

      if (nameA.isEmpty) continue; // 2. Skip audit logic if it has no FDA set_id synced yet

      for (var otherMed in _meds) {
        final String nameB = otherMed['name'] ?? '';
        if (nameB.isEmpty || nameA == nameB) continue;
        final String? interaction = await DatabaseManager().getInteractions(nameA, nameB);

        if (interaction != null) {
          _currentConflicts.add(
            InteractionConflict(
              primaryMedName: primaryMed['name'],
              conflictingMedName: otherMed['name'],
              interaction: interaction,
            ),
          );

          setState(() => primaryMed['has_interaction'] = 1);
        }
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
        _auditRun = true;
        _hasContraIndications = _currentConflicts.isNotEmpty;
      });
    }
  }

  Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _confirmAndSave() {
    // 1. Calculate the audit result index
    int auditResultIndex;

    if (!_auditRun) {
      // User didn't trigger the safety check
      auditResultIndex = MedicationSafetyAudit.auditNotPerformed.index;
    } else if (_currentConflicts.isNotEmpty) {
      // Audit ran and found issues
      auditResultIndex = MedicationSafetyAudit.interactionsDetected.index;
    } else {
      // Audit ran and cleared
      auditResultIndex = MedicationSafetyAudit.interactionsNotDetected.index;
    }

    // 2. Return the data map back to the Roster
    Navigator.pop(context, {'medications': _meds.length, 'medication_safety_audit': auditResultIndex});
  }

  // Logic-driven Banner Widget
  Widget _buildStatusBanner() {
    _dataSheetCount = _countDataSheets();
    if (_meds.isEmpty || _dataSheetCount < 2) {
      return SizedBox(height: 0);
    }
    // Determine state based on your list logic
    BannerData bannerData;
    // Example Logic check:
    if (!_auditRun) {
      bannerData = banners[BannerType.unknown]!;
    } else if (_hasContraIndications) {
      bannerData = banners[BannerType.critical]!;
    } else if (_hasPrecautions) {
      bannerData = banners[BannerType.advisory]!;
    } else if (_acceptedIndications) {
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
          if (_meds.length > 1) Icon(bannerData.icon, color: bannerData.color, size: 20),
          if (_meds.length > 1) const SizedBox(width: 12),
          if (_meds.length > 1)
            Expanded(
              child: Text(
                bannerData.message,
                style: TextStyle(color: bannerData.color, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: CarbonButton(
              label: "Check Again",
              onPressed: _runSafetyAudit,
              icon: Symbols.fact_check,
              color: AppTheme.lightTheme.primaryColorDark,
            ),
          ),
        ],
      ),
    );
  }

  void _refreshMedInUI(String medId, String setId) {
    setState(() {
      final index = _meds.indexWhere((m) => m['id'] == medId);
      if (index != -1) {
        _meds[index]['set_id'] = setId;
        _meds[index]['is_syncing'] = false;
      }
    });
  }

  Future<void> _startBackgroundSync(String medId, String medName) async {
    try {
      //Local Cache Check
      String? existingSetId = await DatabaseManager().getSetIdByName(medName);
      if (existingSetId != null) {
        await DatabaseManager().updateMedicationSetId(medId, existingSetId);
        _refreshMedInUI(medId, existingSetId);
        _runSafetyAudit();
        return;
      }

      // FDA Check
      final drugDataSheet = await MedicationService.getDrugDataSheet(medName, "", medId);
      if (drugDataSheet != null) {
        _refreshMedInUI(medId, drugDataSheet['set_id']);
        _runSafetyAudit();
      }
    } catch (e) {
      debugPrint("Background sync failed for $medName: $e");
    } finally {
      // 3. Ensure the 'is_syncing' flag is cleared even on failure
      _stopSyncSpinner(medId);
    }
  }

  void _stopSyncSpinner(String medId) {
    setState(() {
      final index = _meds.indexWhere((m) => m['id'] == medId);
      if (index != -1) {
        _meds[index]['is_syncing'] = false;
      }
    });
  }

  void _addMedication(String medicationName) async {
    if (medicationName.isNotEmpty) {
      var uuid = const Uuid();
      final String medId = uuid.v4();

      final newMed = {
        "id": medId,
        "patient_uuid": widget.patient.patientUuid,
        "name": medicationName,
        "image_uri": "holder",
        "dose": dosageController.text,
        "freq": "PRN",
        "set_id": "", // <--- This is empty, causing your DB query to fail
        "has_local_datasheet": 0, // <--- Explicitly set this to avoid null checks
      };

      // Update UI immediately
      setState(() {
        _meds.add({...newMed, "is_syncing": true});

        // Sort the list by name
        _meds.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
        frequencyController.clear();
        nameController.clear();
        dosageController.clear();
      });

      // Database & Background logic
      // Wrap in try-catch to prevent silent failures
      try {
        await DatabaseManager().insertMedication(newMed);
        await _startBackgroundSync(medId, medicationName);
      } catch (e) {
        // Handle or log error
        print("Error saving medication: $e");
      }
    }
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
    final name = "${widget.patient.firstName} ${widget.patient.lastName}";
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      appBar: AppBar(
        title: Align(
          alignment: AlignmentGeometry.centerLeft,
          child: Text("Medications: $name", style: AppTheme.carbonTextStyle),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _confirmAndSave,
            child: Text("SAVE", style: AppTheme.carbonPrimaryButtonTextStyle),
          ),
        ],
        backgroundColor: AppTheme.carbonScaffoldColor, // Your Navy brand color
        foregroundColor: AppTheme.carbonPrimary,
      ),
      // The Floating Action Button replaces the top form
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          key: Key("FAB_NewMedication"),
          onPressed: () => showAddMedicationSheet(),
          child: const Icon(Symbols.add, size: 32),
        ),
      ),
      body: Column(
        children: [
          _buildStatusBanner(),
          // CURRENT LIST: The Baseline
          Expanded(
            child: ListView.builder(
              itemCount: _meds.length,
              itemBuilder: (context, index) {
                final med = _meds[index];

                // We swap the old ListTile for our new smart card
                return MedicationCard(
                  key: ValueKey(med['id']),
                  interactions: _currentConflicts,
                  medData: med,
                  index: index,
                  onDelete: () async {
                    final String medIdToDelete = med['id'];

                    // 1. Remove from the local database
                    await DatabaseManager().deleteMedication(medIdToDelete);

                    // 2. Remove from the UI state
                    setState(() {
                      _meds.removeAt(index);
                      _dataSheetCount = _countDataSheets();
                    });
                  },
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      med["has_local_datasheet"] = 1;
                      _dataSheetCount = _countDataSheets();
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
