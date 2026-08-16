import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../classes/allergen.dart';
import '../classes/carbon_color_constants.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/database_manager.dart';
import 'carbon_button_compact.dart';
import 'carbon_segmented_control.dart';
import 'carbon_style_textbox.dart';

// "Tap the chip for detail" — same role as ConfigureConditionDialog, but allergies
// don't have onset/duration/status the way a medical condition does; you either have
// the allergy or you don't (removing the chip is how you say you don't). The two
// things actually worth recording are how bad the reaction is and what it looks like —
// severity feeds the drug-allergy cross-check on the medication safety audit (see
// prescription_screen.dart), reaction is just for the patient's/a clinician's reference.
class ConfigureAllergyDialog extends StatefulWidget {
  final PatientAllergy patientAllergy;

  const ConfigureAllergyDialog({super.key, required this.patientAllergy});

  @override
  State<ConfigureAllergyDialog> createState() => _ConfigureAllergyDialogState();
}

class _ConfigureAllergyDialogState extends State<ConfigureAllergyDialog> {
  late AllergySeverity _severity;
  late TextEditingController _reactionController;

  @override
  void initState() {
    super.initState();
    _severity = widget.patientAllergy.severity;
    _reactionController = TextEditingController(text: widget.patientAllergy.reaction);
  }

  @override
  void dispose() {
    _reactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double availableWidth = MediaQuery.of(context).size.width;
    final double fixedDialogWidth = availableWidth - 64;

    return Dialog(
      backgroundColor: carbonColorLayer02,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: fixedDialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 8, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          widget.patientAllergy.name,
                          style: CarbonTheme.carbonHeadingTextStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Symbols.close, color: carbonColorIconSecondary),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SEVERITY", style: CarbonTheme.carbonLabelTextStyle),
                    const SizedBox(height: 6),
                    CarbonSegmentedControl<AllergySeverity>(
                      options: AllergySeverity.values,
                      value: _severity,
                      labelBuilder: (s) => s.label,
                      onChanged: (s) => setState(() => _severity = s),
                    ),
                    const SizedBox(height: 16),
                    CarbonTextInput(
                      label: "Reaction",
                      helperText: "What happens when you're exposed?",
                      controller: _reactionController,
                      maxLines: 3,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: CarbonCompactButton(
                  icon: Symbols.check,
                  label: "Confirm Changes",
                  style: CarbonButtonStyle.primary,
                  onTap: () async {
                    widget.patientAllergy.severity = _severity;
                    widget.patientAllergy.reaction = _reactionController.text.trim();

                    final navigator = Navigator.of(context);
                    await DatabaseManager().updatePatientAllergy(widget.patientAllergy);

                    if (mounted) navigator.pop(true);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
