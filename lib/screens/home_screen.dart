import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/action.dart';
import 'package:triage/screens/time_scroller.dart';
import '../app_theme.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../widgets/emergency_qr.dart';
import '../widgets/user_card.dart';
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
    final List<PatientAction> actions = PatientActionFactory.instance.getActionsForPatient(patient.patientUuid);
    return [
      UserCard(
        householdMember: patient,
        onVitalsUpdate: (p) => updatePatient(patientIndex: patientIndex, patient: p),
        onMemberUpdate: (p) => updatePatient(patientIndex: patientIndex, patient: p),
      ),
      const StaffScreen(),
      MedicalProfileScreen(householdMember: patient),
      PrescriptionScreen(patient: patient),
      EmergencyQRCodeView(householdMember: patient),
      TimelineScrollerWidget(actions: actions, startTime: DateTime(2025), endTime: DateTime.now()),
    ];
  }

  void _jumpToPatient(int index) {
    _pageController.jumpToPage(index);
    Navigator.pop(context);
  }

  void _showMemberJumpList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) =>
            ListTile(title: Text(patients[index].name), onTap: () => _jumpToPatient(index)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
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
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: AppColors.grey.all[2], blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const SizedBox(width: 60),
                  _navButton(index: 1, icon: Symbols.diversity_4),
                  _navButton(index: 2, icon: Symbols.conditions),
                  _navButton(index: 3, icon: Symbols.medication),
                  _navButton(index: 4, icon: Symbols.qr_code_2),
                  _navButton(index: 5, icon: Symbols.view_object_track),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: -15,
            child: GestureDetector(
              onLongPress: () => _showMemberJumpList(context),
              onTap: () => setState(() => _currentIndex = 0),
              child: _buildPatientAvatar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton({required int index, required IconData icon}) {
    return IconButton(
      icon: Icon(icon),
      color: _currentIndex == index ? AppColors.oceanBlue : AppColors.peacockBlue,
      onPressed: () => setState(() => _currentIndex = index),
    );
  }

  Widget _buildPatientAvatar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: const CircleAvatar(radius: 32, backgroundImage: AssetImage("assets/images/faces/dr_face_1.png")),
    );
  }
}
