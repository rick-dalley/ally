import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:carbon_ui/widgets/carbon_style_autocomplete.dart';

import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import 'package:carbon_ui/widgets/carbon_style_full_button.dart';
import '../classes/drug_name_matcher.dart';
import '../classes/medication_label_scanner.dart';
import 'scan_medication_label.dart';

class GetMedicationName extends StatefulWidget {
  final TextEditingController nameController;
  final Function(String) onAddMedication;
  final Function(String)? onSearchMedication;
  /// Fired when a label scan has been read AND confirmed by the person. Carries the
  /// whole label so the wizard can pre-fill the steps after this one, not just the name.
  final Function(ScannedMedicationLabel)? onLabelScanned;

  const GetMedicationName({
    super.key,
    required this.nameController,
    required this.onAddMedication,
    this.onSearchMedication,
    this.onLabelScanned,
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
          Align(
            alignment: Alignment.centerLeft,
            // Says "label", not "bar code", and means it. The bar code on a dispensed
            // bottle is the pharmacy's own fill number — it identifies the prescription
            // inside that one pharmacy's system and carries no drug identity, so there
            // is nothing Ally could resolve it against. The drug name, strength and
            // directions are all printed as text right beside it, which reads on-device
            // with no lookup at all.
            child: Text("Scan the printed label on the pill bottle", style: CarbonTheme.carbonHintTextStyle),
          ),
          const SizedBox(height: 24),
          CarbonFullButton(
            label: 'SCAN LABEL',
            onTap: _startLabelScan,
            style: CarbonButtonStyle.tertiary,
            icon: Symbols.document_scanner,
          ),

          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Or enter it manually", style: CarbonTheme.carbonHintTextStyle),
          ),
          const SizedBox(height: 24),

          // Ranked type-ahead over the bundled generic-name vocabulary rather than a
          // bare text box. Three or four letters is enough to land a name nobody wants
          // to spell on a phone keyboard, and the same matcher resolves a fragment a
          // scan only half-read — see DrugNameMatcher.
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

  Future<void> _startLabelScan() async {
    final ScannedMedicationLabel? scanned = await Navigator.push<ScannedMedicationLabel>(
      context,
      MaterialPageRoute(builder: (_) => const ScanMedicationLabel()),
    );

    // Null means they backed out or the read failed — leave whatever they had typed
    // alone rather than clearing the field out from under them.
    if (scanned == null || !mounted) return;

    setState(() {
      widget.nameController.text = scanned.name ?? widget.nameController.text;
    });

    widget.onAddMedication(widget.nameController.text);
    widget.onLabelScanned?.call(scanned);
  }
}
