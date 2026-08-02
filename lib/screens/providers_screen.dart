import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_color_constants.dart';
import 'package:triage/classes/carbon_theme_constants.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/classes/provider.dart';
import 'package:triage/widgets/provider_card_widget.dart';
import '../app_theme.dart';
import '../classes/patient.dart';
import '../widgets/add_care_provider.dart';
import '../widgets/carbon_style_button.dart';

class ProviderRosterScreen extends StatefulWidget {
  final Patient user;
  const ProviderRosterScreen({super.key, required this.user});

  @override
  State<ProviderRosterScreen> createState() => ProviderRosterScreenState();
}

class ProviderRosterScreenState extends State<ProviderRosterScreen> {
  late Future<List<Map<String, dynamic>>> providers;

  @override
  void initState() {
    super.initState();
    loadStaffKeys();
  }

  void loadStaffKeys() {
    // DatabaseManager is a singleton, so this is safe and fast
    setState(() {
      providers = DatabaseManager().getProviders(widget.user.patientUuid);
    });
  }

  void handleCardUpdated(String providerUuid) {
    loadStaffKeys();
  }

  void handleCardDeleted(Provider provider) {
    provider.delete();
    loadStaffKeys();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Health Care Team"),
        backgroundColor: carbonColorScaffoldBackground,
        actions: [CarbonIconButton(icon: Symbols.search, onPressed: () {})],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: providers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor, // Navy indicator for a "smart" feel
              ),
            );
          } else if (snapshot.hasError) {
            debugPrint("ProviderRosterScreen Error: ${snapshot.error}");
            debugPrint("Stack trace: ${snapshot.stackTrace}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error loading care team:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
            );
          }

          final providerList = snapshot.data ?? [];

          if (providerList.isEmpty) {
            return Center(child: Text("No care providers found.", style: CarbonTheme.carbonLabelTextStyle));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 90),
            // Added top padding for breathing room
            itemCount: providerList.length,
            itemBuilder: (context, index) {
              final providerMap = providerList[index];
              final Provider provider = Provider.fromJson(providerMap);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ProviderCard(
                  provider: provider,
                  user: widget.user,
                  index: index,
                  onCardUpdated: handleCardUpdated,
                  onDeleteCard: handleCardDeleted,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          key: const Key("FAB_NewCareGiver"),
          heroTag: "providers_screen",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddCareProviderScreen(patientUuid: widget.user.patientUuid)),
            );
          },
          // Signals scanning capability
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.onPrimaryColor,
          shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
          child: const Icon(Symbols.person_add, size: 32),
        ),
      ),
    );
  }
}
