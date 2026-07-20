import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/patient_action.dart';
import 'package:triage/screens/add_patients_wheel.dart';
import 'package:triage/screens/time_scroller.dart';
import 'package:triage/screens/user_screen.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../widgets/emergency_qr.dart';
import 'prescription_screen.dart';
import 'staff_screen.dart';
import 'medical_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _currentPageIndex = 0;
  List<Patient> patients = [];
  bool _isLoading = true;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    loadPatientData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> loadPatientData() async {
    final data = await DatabaseManager().getAllPatientsWithVitals();
    if (mounted) {
      setState(() {
        patients = data.map((p) => Patient.fromJson(p)).toList();
        _isLoading = false;
      });
    }
  }

  void updatePatient({required int patientIndex, required Patient patient}) {
    setState(() {
      patients[patientIndex] = patient;
    });
  }

  List<Widget> _getPages(int patientIndex) {
    final patient = patients[patientIndex];
    final List<PatientAction> actions = patientActions;
    final startTime = actions.first.occurred.toUtc();
    final endTime = actions.last.until;

    return [
      UserScreen(
        user: patient,
        onVitalsUpdate: (p) => updatePatient(patientIndex: patientIndex, patient: p),
        onMemberUpdate: (p) => updatePatient(patientIndex: patientIndex, patient: p),
      ),
      const StaffScreen(),
      MedicalProfileScreen(householdMember: patient),
      PrescriptionScreen(patient: patient),
      EmergencyQRCodeView(householdMember: patient),
      TimelineScrollerWidget(actions: actions, startTime: startTime, endTime: endTime),
    ];
  }

  void _jumpToPatient(int index) {
    _pageController.jumpToPage(index);
    Navigator.pop(context);
  }

  void _showMemberJumpList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPatientsWheel(
        familyMembers: patients,
        onDismiss: () {
          Navigator.pop(context);
        },
        onUserSelected: (dynamic patientUuid) {},
        onAddMember: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: PageView.builder(
        controller: _pageController,
        itemCount: patients.length,
        onPageChanged: (index) => setState(() => _currentPageIndex = index),
        itemBuilder: (context, index) {
          return IndexedStack(index: _currentIndex, children: _getPages(index));
        },
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return SizedBox(
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: ClipRect(
              // Required for BackdropFilter to work
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  height: 90,
                  // Use a color with a lower alpha to let the blur show through
                  color: AppTheme.lightTheme.canvasColor.withValues(alpha: 0.25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 88),
                      _navButton(index: 1, icon: Symbols.diversity_4),
                      _navButton(index: 2, icon: Symbols.conditions),
                      _navButton(index: 3, icon: Symbols.medication),
                      _navButton(index: 4, icon: Symbols.qr_code_2),
                      _navButton(index: 5, icon: Symbols.view_object_track),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: -15,
            child: GestureDetector(
              onLongPress: () => _showMemberJumpList(context),
              onTap: () => setState(() => _currentIndex = 0),
              child: _buildPatientAvatar(patients[_currentPageIndex].name),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton({required int index, required IconData icon}) {
    final bool isSelected = _currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      // Add padding/margin inside the container to make it a pill or square
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.lightTheme.primaryColorDark : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Icon(
          icon,
          size: 32,
          // If selected, force white; otherwise use the dark primary color
          color: isSelected ? AppColors.grey.all[0] : AppTheme.lightTheme.primaryColorDark,
        ),
      ),
    );
  }

  Widget _buildPatientAvatar(String patientName) {
    final bool isSelected = _currentIndex == 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      // Adjust padding to keep it circular/balanced compared to icon buttons
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.lightTheme.primaryColorDark : Colors.transparent,
        shape: BoxShape.circle, // Keeps the selection highlight circular
        border: Border.all(color: isSelected ? AppColors.oceanBlue : Colors.transparent, width: 4),
      ),
      child: InkWell(
        customBorder: const CircleBorder(), // Ensures the ripple effect is circular
        onTap: () => setState(() => _currentIndex = 0),
        child: CircleAvatar(
          radius: 30, // Slightly smaller to accommodate the 4px border inside the container
          backgroundImage: AssetImage("assets/images/faces/users/$patientName.png"),
        ),
      ),
    );
  }
}
