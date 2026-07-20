import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/staff.dart';
import 'package:triage/widgets/staff_card_widget.dart';
import '../app_theme.dart';
import '../widgets/add_care_provider.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => StaffScreenState();
}

class StaffScreenState extends State<StaffScreen> {
  List<String> staffKeys = [];

  @override
  void initState() {
    super.initState();
    _loadStaffKeys();
  }

  Future<void> _loadStaffKeys() async {
    // DatabaseManager is a singleton, so this is safe and fast
    staffKeys = StaffFactory.instance.getStaffKeys();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Team"), backgroundColor: AppTheme.lightTheme.canvasColor.withValues(alpha: 0.25)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      backgroundColor: Colors.transparent,
      body: staffKeys.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.peacockBlue, // Navy indicator for a "smart" feel
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 90),
              // Added top padding for breathing room
              itemCount: staffKeys.length,
              itemBuilder: (context, index) {
                StaffMember? staffMember = StaffFactory.instance.getStaffMember(id: staffKeys[index]);
                return StaffIdCard(photoPath: 'photoPath', staffMember: staffMember, index: index);
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          key: Key("FAB_NewCareGiver"),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCareProviderScreen()));
          },
          // Signals scanning capability
          backgroundColor: AppColors.oceanBlue,
          foregroundColor: AppColors.grey.all[0],
          shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
          child: const Icon(Symbols.person_add, size: 32),
        ),
      ),
    );
  }
}
