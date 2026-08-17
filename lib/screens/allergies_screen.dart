import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import '../classes/allergen.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import '../widgets/allergy_chip.dart';
import 'package:carbon_ui/widgets/carbon_quick_entry_field.dart';
import '../widgets/halo_ripple_chip.dart';

class AllergyCategoryStyle {
  final IconData iconData;
  final Color color;
  const AllergyCategoryStyle({required this.iconData, required this.color});
}

// Same distinguishing-accent-color convention as physical_health.dart's categoryIcons
// — decorative category hues for a chip-heavy screen, not semantic Carbon tokens
// (Carbon's semantic palette is functional: primary/success/warning/error, it doesn't
// have five-plus distinguishable decorative hues to draw from). Drug allergies get the
// one color that doubles as a real signal — red — since that's the category the
// medication safety-audit cross-check actually watches (see prescription_screen.dart).
final Map<String, AllergyCategoryStyle> allergyCategoryStyles = {
  "Environmental & Airborne Allergens": AllergyCategoryStyle(
    iconData: iconForAllergenCategory("Environmental & Airborne Allergens"),
    color: Color(0xFF0298BA),
  ),
  "Food Allergens": AllergyCategoryStyle(
    iconData: iconForAllergenCategory("Food Allergens"),
    color: Color(0xFF2E7D32),
  ),
  "Medications & Drug Allergies": AllergyCategoryStyle(
    iconData: iconForAllergenCategory("Medications & Drug Allergies"),
    color: Color(0xFFBA0000),
  ),
  "Insect Stings": AllergyCategoryStyle(
    iconData: iconForAllergenCategory("Insect Stings"),
    color: Color(0xFFBA5D00),
  ),
  "Skin & Contact Allergens": AllergyCategoryStyle(
    iconData: iconForAllergenCategory("Skin & Contact Allergens"),
    color: Color(0xFF64008C),
  ),
  "Custom": AllergyCategoryStyle(
    iconData: iconForAllergenCategory("Custom"),
    color: Color(0xFF525252),
  ),
};

AllergyCategoryStyle _styleFor(String category) =>
    allergyCategoryStyles[category] ?? allergyCategoryStyles["Custom"]!;

class AllergiesScreen extends StatefulWidget {
  final String patientUuid;
  final ScrollController scrollController;

  const AllergiesScreen({
    super.key,
    required this.patientUuid,
    required this.scrollController,
  });

  @override
  State<AllergiesScreen> createState() => AllergiesScreenState();
}

class AllergiesScreenState extends State<AllergiesScreen> {
  late Future<Map<String, List<AllergenReference>>> _catalogFuture;
  late Future<List<PatientAllergy>> _patientAllergies;
  List<AllergenReference> _allAllergensFlat = [];

  @override
  void initState() {
    super.initState();
    _patientAllergies = DatabaseManager().getAllergiesForPatient(
      widget.patientUuid,
    );
    _loadCatalog();
  }

  void _loadCatalog() {
    _catalogFuture = DatabaseManager().getAllergensCatalog().then((data) {
      setState(
        () => _allAllergensFlat = data.values.expand((list) => list).toList(),
      );
      return data;
    });
  }

  // Mirrors physical_health.dart's _addCustomCondition — filed under "Custom" so it
  // gets a chip and full severity/reaction editing exactly like a catalog pick.
  Future<void> _addCustomAllergen(String name) async {
    final int allergenId = await DatabaseManager().getOrCreateCustomAllergen(
      name,
    );
    await DatabaseManager().insertPatientAllergy(
      PatientAllergy(
        patientUuid: widget.patientUuid,
        allergenId: allergenId,
        name: name,
        category: 'Custom',
      ),
    );
    setState(() {
      _patientAllergies = DatabaseManager().getAllergiesForPatient(
        widget.patientUuid,
      );
    });
    _loadCatalog();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PatientAllergy>>(
      future: _patientAllergies,
      builder: (context, patientSnapshot) {
        final List<PatientAllergy> liveAllergies = patientSnapshot.data ?? [];
        final bool hasAllergies = liveAllergies.isNotEmpty;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "KNOWN ALLERGIES",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: !hasAllergies
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: !hasAllergies ? Colors.transparent : carbonColorField,
                borderRadius: BorderRadius.zero,
                border: !hasAllergies
                    ? null
                    : Border.all(color: carbonColorBorderStrong01, width: 1),
              ),
              child: !hasAllergies
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Symbols.allergy,
                              size: 16,
                              color: carbonColorTextPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Allergies on file",
                              style: CarbonTheme.carbonTextStyle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: liveAllergies.map((PatientAllergy allergy) {
                            final ref = _allAllergensFlat.firstWhere(
                              (a) => a.id == allergy.allergenId,
                              orElse: () => AllergenReference(
                                id: allergy.allergenId,
                                name: allergy.name,
                                category: allergy.category,
                              ),
                            );
                            allergy.name = ref.name;
                            allergy.category = ref.category;
                            return AllergyChip(
                              patientAllergy: allergy,
                              icon: _styleFor(ref.category).iconData,
                              color: _styleFor(ref.category).color,
                              onDeleteAllergy: (int id) async {
                                await DatabaseManager().deletePatientAllergy(
                                  id,
                                );
                                setState(() {
                                  _patientAllergies = DatabaseManager()
                                      .getAllergiesForPatient(
                                        widget.patientUuid,
                                      );
                                });
                              },
                              onUpdateAllergy: () {
                                setState(() {
                                  _patientAllergies = DatabaseManager()
                                      .getAllergiesForPatient(
                                        widget.patientUuid,
                                      );
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
            ),
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  CarbonQuickEntryField(
                    label: "Don't see it below?",
                    hintText: "Type an allergy and tap the check to add it",
                    onSave: _addCustomAllergen,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Tap anything below that you're allergic to.",
                    style: CarbonTheme.carbonHelperTextStyle,
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder<Map<String, List<AllergenReference>>>(
                    future: _catalogFuture,
                    builder: (context, catalogSnapshot) {
                      if (catalogSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (catalogSnapshot.hasError ||
                          !catalogSnapshot.hasData) {
                        return const Text(
                          "Failed to load allergen catalog from disk.",
                          style: TextStyle(color: Colors.red),
                        );
                      }
                      final catalogMap = catalogSnapshot.data!;
                      return Container(
                        width: double.infinity,
                        alignment: Alignment.topLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: catalogMap.entries
                              .map(
                                (group) => _buildGroup(
                                  group.key,
                                  group.value,
                                  liveAllergies,
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroup(
    String category,
    List<AllergenReference> allergens,
    List<PatientAllergy> liveRecords,
  ) {
    final style = _styleFor(category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Same fix as physical_health.dart's _buildGroup — HaloRippleChip's own
            // Row has a Flexible(Text) that needs bounded width from its immediate
            // parent, which a bare Row's non-flex child never gets. Same crash
            // ("RenderFlex children have non-zero flex but incoming width
            // constraints are unbounded") without Expanded here.
            Expanded(
              child: HaloRippleChip(
                iconData: style.iconData,
                text: category,
                color: style.color,
                backgroundColor: Color(0xFF000000),
                animate: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allergens.map((allergen) {
            final bool isSelected = liveRecords.any(
              (pa) => pa.allergenId == allergen.id,
            );
            return FilterChip(
              label: Text(allergen.name),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.onPrimaryColor : style.color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : style.color.withAlpha(128),
                width: 1.5,
              ),
              color: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.selected)) return style.color;
                return style.color.withAlpha(20);
              }),
              selected: isSelected,
              onSelected: (bool selected) async {
                if (selected) {
                  await DatabaseManager().insertPatientAllergy(
                    PatientAllergy.fromAllergen(widget.patientUuid, allergen),
                  );
                } else {
                  final recordToRemove = liveRecords.firstWhere(
                    (pa) => pa.allergenId == allergen.id,
                  );
                  if (recordToRemove.id != null) {
                    await DatabaseManager().deletePatientAllergy(
                      recordToRemove.id!,
                    );
                  }
                }
                setState(() {
                  _patientAllergies = DatabaseManager().getAllergiesForPatient(
                    widget.patientUuid,
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
