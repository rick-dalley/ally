import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/screens/intake.dart';
import 'package:triage/widgets/card_flipper.dart';
import 'package:triage/widgets/household_member_info_card.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../widgets/household_member_medical_card.dart';
import 'questionnaires.dart';
import 'meds.dart';

class FamilyRoster extends StatefulWidget {
  const FamilyRoster({super.key});

  @override
  State<FamilyRoster> createState() => FamilyRosterState();
}

class FamilyRosterState extends State<FamilyRoster> {
  List<dynamic> _patients = [];
  String _searchQuery = "";
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadPatientData();
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
  }

  Future<void> _loadPatientData() async {
    // DatabaseManager is a singleton, so this is safe and fast
    final data = await DatabaseManager().getAllPatientsWithVitals();

    setState(() {
      _patients = data.map((p) => Patient.fromJson(p)).toList();
    });
  }

  void updatePatient({required int index, required Patient patient}) {
    setState(() {
      _patients[index] = patient;
    });
  }

  void _showAssessmentsMenu(BuildContext context, String patientUuid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssessmentsScreen(patientUuid: patientUuid),
    );
  }

  void _launchEncounterScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntakeScreen(),
        // This ensures the screen slides up like a focused task
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We remove the AppBar here because it's now handled by LuminescaHome in main.dart
    final filteredPatients = _patients.where((p) {
      final name = "${p.firstName} ${p.lastName}".toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      // Keeping the body as the main focus
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by name...",
                      prefixIcon: const Icon(Icons.search),
                      // Add this to your decoration
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = ""; // Reset the query
                                  _searchController.clear();
                                });
                              },
                            )
                          : null, // No icon if the field is empty
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredPatients.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.deepLogicViolet, // Navy indicator for a "smart" feel
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    // Added top padding for breathing room
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      return FlippableCardController(
                        height: 332,
                        front: HouseholdMemberMedicalCard(
                          householdMember: filteredPatients[index],
                          onMemberUpdate: ({required Patient patient}) {
                            updatePatient(index: index, patient: patient);
                          },
                          onVitalsUpdate: ({required Patient patient}) {
                            updatePatient(index: index, patient: patient);
                          },
                          onAssessmentsTap: () => _showAssessmentsMenu(context, filteredPatients[index].patientUuid),
                          onMedsTap: () async {
                            final Map<String, dynamic>? result = await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              showDragHandle: true,
                              builder: (context) => MedicationScreen(patient: filteredPatients[index]),
                            );

                            if (result != null) {
                              setState(() {
                                // Create the writable copy to avoid read-only errors
                                Patient updatedPatient = filteredPatients[index];
                                // Map the returned values to our flat patient structure
                                updatedPatient.medications = result['medications'];
                                updatedPatient.medicationSafetyAudit = result['medication_safety_audit'];
                                filteredPatients[index] = updatedPatient;
                              });
                            }
                          },
                        ),
                        back: HouseholdMemberInformationCard(patient: filteredPatients[index]),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _launchEncounterScreen(context),
        // New dedicated screen
        label: const Text("+", style: TextStyle(letterSpacing: 1.0, fontWeight: FontWeight.w600)),
        icon: const Icon(Symbols.frame_person),
        // Signals scanning capability
        backgroundColor: AppTheme.deepLogicViolet,
        foregroundColor: AppTheme.clinicalWhite,
      ),
    );
  }
}
