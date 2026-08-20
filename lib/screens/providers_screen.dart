import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:ally/classes/database_manager.dart';
import 'package:ally/classes/provider.dart';
import 'package:ally/widgets/provider_card_widget.dart';
import '../classes/patient.dart';
import '../widgets/add_care_provider.dart';
import 'package:carbon_ui/widgets/carbon_style_button.dart';

class ProviderRosterScreen extends StatefulWidget {
  final Patient user;
  const ProviderRosterScreen({super.key, required this.user});

  @override
  State<ProviderRosterScreen> createState() => ProviderRosterScreenState();
}

class ProviderRosterScreenState extends State<ProviderRosterScreen> {
  late Map<String, Provider>? providers = {};

  @override
  void initState() {
    super.initState();
    loadProviders();
  }

  Future<void> loadProviders() async {
    dynamic rawProviders = await DatabaseManager().getProviders(widget.user.patientUuid);
    if (rawProviders != null) {
      for (dynamic rp in rawProviders) {
        Provider provider = Provider.fromJson(rp);
        if (providers != null) {
          providers?[provider.id] = provider;
        }
      }
    }
  }

  void handleCardUpdated(Provider provider) {
    setState(() {
      if (providers != null) {
        providers?[provider.id] = provider;
      }
    });
  }

  void handleCardDeleted(Provider provider) {
    provider.delete();
    loadProviders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: carbonColorScaffoldBackground,
        actions: [CarbonIconButton(icon: Symbols.search, onPressed: () {})],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      backgroundColor: Colors.transparent,
      body: providers!.isEmpty
          ? Center(child: Text("No care providers found.", style: CarbonTheme.carbonLabelTextStyle))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 90),
              itemCount: providers!.length,
              itemBuilder: (context, index) {
                // Convert map values to an iterable index lookup
                final Provider provider = providers!.values.elementAt(index);

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
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          backgroundColor: carbonColorPrimary04,
          foregroundColor: carbonColorButtonOnPrimary,
          key: const Key("FAB_NewCareGiver"),
          heroTag: "providers_screen",
          onPressed: () async {
            final Provider? provider = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddCareProviderScreen(patientUuid: widget.user.patientUuid)),
            );

            if (provider != null) {
              setState(() {
                provider.save();
                loadProviders();
              });
            }
          },
          // Signals scanning capability
          shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
          child: const Icon(Symbols.person_add, size: 32),
        ),
      ),
    );
  }
}
