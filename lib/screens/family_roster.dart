import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/screens/user_screen.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../widgets/carbon_style_search_field.dart';
import 'intake_screen.dart';
import 'medical_profile_screen.dart';
import 'prescription_screen.dart';

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

  void _showAssessmentsMenu(BuildContext context, Patient householdMember) {
    showModalBottomSheet(
      context: context,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      isScrollControlled: true,
      backgroundColor: AppColors.grey.all[0],
      useSafeArea: true,
      builder: (context) => MedicalProfileScreen(householdMember: householdMember),
    );
  }

  void _launchIntakeScreen(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
            child: CarbonSearchField(
              controller: _searchController,
              label: "",
              hintText: "Search by name",
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: filteredPatients.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.peacockBlue, // Navy indicator for a "smart" feel
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    // Added top padding for breathing room
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      return UserScreen(
                        user: filteredPatients[index],
                        onMemberUpdate: (Patient patient) {
                          updatePatient(index: index, patient: patient);
                        },
                        onVitalsUpdate: (Patient patient) {
                          updatePatient(index: index, patient: patient);
                        },
                        onAssessmentsTap: () => _showAssessmentsMenu(context, filteredPatients[index]),
                        onMedsTap: () async {
                          final Map<String, dynamic>? result = await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            showDragHandle: true,
                            builder: (context) => PrescriptionScreen(patient: filteredPatients[index]),
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
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _launchIntakeScreen(context),
        // Signals scanning capability
        backgroundColor: AppColors.peacockBlue,
        foregroundColor: AppTheme.clinicalWhite,
        shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
        // New dedicated screen
        icon: Icon(Symbols.frame_person_sharp, size: 24),
        label: Text("Add Member"),
      ),
    );
  }
}
