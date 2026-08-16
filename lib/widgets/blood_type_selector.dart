import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/widgets/carbon_style_button.dart';
import 'package:triage/widgets/carbon_style_dropdown.dart';
import '../classes/blood_type.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/listable.dart';

class BloodTypeSelector extends StatelessWidget {
  final AboType selectedAbo;
  final RhFactor selectedRh;
  final ValueChanged<Listable> onAboChanged;
  final ValueChanged<Listable> onRhChanged;
  // The Cancel/Save row assumes it's being shown via showModalBottomSheet (its only
  // use until FirstPatientWizard embedded this directly in a wizard page, which isn't
  // a pushed route — Navigator.pop() there would pop the wrong thing or have nothing
  // to pop). Callers that provide their own Next/Skip controls set this to false.
  final bool showActions;

  const BloodTypeSelector({
    super.key,
    required this.selectedAbo,
    required this.selectedRh,
    required this.onAboChanged,
    required this.onRhChanged,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 32, right: 16, left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                "Blood Type",
                style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
              ),
              Spacer(),
              const Icon(Symbols.bloodtype_sharp, color: Colors.red),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Select your blood type below. A blood type is a combination of ABO group and Rh factor (e.g., AB-).",
          ),
          SizedBox(height: 16),
          _buildDropdown(context),
          const SizedBox(width: 16),
          _buildRhDropdown(context),
          if (showActions) ...[
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CarbonButton(
                    label: "Cancel",
                    style: CarbonButtonStyle.secondary,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Expanded(
                  child: CarbonButton(
                    label: "Save",
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    return CarbonDropdown<AboType>(
      label: "ABO Group",
      placeholder: "Select A, B, AB or O",
      helperText: "Select your blood type",
      items: AboType.values,
      onChanged: onAboChanged,
      value: selectedAbo,
    );
  }

  Widget _buildRhDropdown(BuildContext context) {
    return CarbonDropdown<RhFactor>(
      label: "RH Factor",
      placeholder: "Select +/-",
      helperText: "Select whether your blood type is RH positive or negative",
      items: RhFactor.values,
      onChanged: onRhChanged,
      value: selectedRh,
    );
  }
}
