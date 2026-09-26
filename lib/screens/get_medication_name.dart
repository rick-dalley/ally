import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:carbon_ui/widgets/carbon_style_autocomplete.dart';

import 'package:carbon_ui/colors/carbon_color_constants.dart';
import '../classes/drug_name_matcher.dart';

class GetMedicationName extends StatefulWidget {
  final TextEditingController nameController;
  final Function(String) onAddMedication;
  final Function(String)? onSearchMedication;

  const GetMedicationName({
    super.key,
    required this.nameController,
    required this.onAddMedication,
    this.onSearchMedication,
  });

  @override
  State<StatefulWidget> createState() => GetMedicationNameState();
}

class GetMedicationNameState extends State<GetMedicationName> {
  @override
  Widget build(BuildContext context) {
    // No viewInsets padding here on purpose: the hosting sheet already applies it
    // once (PrescriptionScreen.showAddMedicationSheet), and this page applying it
    // again shrank the step a second time — which is what put the name field itself
    // under the keyboard. Scrollable instead, so the field stays reachable whatever
    // height is left once the keyboard is up.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Add a medication", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
          ),
          const SizedBox(height: 24),
          // Ranked type-ahead over the bundled generic-name vocabulary rather than a
          // bare text box. Three or four letters is enough to land a name nobody wants
          // to spell on a phone keyboard — see DrugNameMatcher.
          CarbonAutocomplete(
            label: "Medication Name",
            controller: widget.nameController,
            placeholder: "Start typing — e.g. \"hydro\"",
            helperText: "Type a few letters and pick from the list, or type it out in full.",
            filter: (String query) => drugNames.suggest(query),
            onChanged: (String value) {
              widget.onSearchMedication?.call(value);
              // Keeps the wizard's progress bar and Save in step with the field.
              widget.onAddMedication(value);
            },
          ),
          const SizedBox(height: 40),
          SvgPicture.asset(
            "assets/images/pills.svg",
            width: 96,
            height: 96,
            colorFilter: ColorFilter.mode(carbonColorInteractive, BlendMode.srcIn),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
