import 'package:flutter/material.dart';
import 'package:triage/widgets/carbon_style_textbox.dart';
import '../classes/patient.dart';
import 'body_metrics_widget.dart';

class StringValuePair {
  final String label;
  final dynamic value;

  const StringValuePair({required this.value, required this.label});
}

class Tuple {
  final StringValuePair first;
  final StringValuePair second;

  const Tuple({required this.first, required this.second});
}

class HouseholdMemberInformationCard extends StatefulWidget {
  final Patient patient;

  const HouseholdMemberInformationCard({super.key, required this.patient});

  @override
  State<StatefulWidget> createState() => HouseholdMemberInformationCardState();
}

class HouseholdMemberInformationCardState extends State<HouseholdMemberInformationCard> {
  late Patient patient;
  String heightUom = "cm";
  String weightUom = "kg";

  @override
  void initState() {
    super.initState();
    patient = widget.patient;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line 1: Patient Name & Process Timer
        CarbonTextEdit(
          label: 'Provincial Health #:',
          helperText: "Enter your government issued health identification",
          value: _formatPHN(patient.phn.toString()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: CarbonTextEdit(label: "Born:", value: patient.formattedDateOfBirth),
            ),
            SizedBox(width: 8),
            Expanded(child: Text("(${patient.age} yrs)")),
          ],
        ),
        SizedBox(height: 16),
        BodyMetricsWidget(patient: patient),
        SizedBox(height: 16),
        _buildTuple(
          Tuple(
            first: StringValuePair(label: "CONTACT:", value: patient.contactName),
            second: StringValuePair(label: "PHONE:", value: patient.contactPhone),
          ),
        ),
        SizedBox(height: 16),
        _buildTuple(
          Tuple(
            first: StringValuePair(label: "DOCTOR:", value: patient.familyDoctorName),
            second: StringValuePair(label: "PHONE:", value: patient.familyDoctorPhone),
          ),
        ),
        SizedBox(height: 16),
        _buildTuple(
          Tuple(
            first: StringValuePair(label: "PHARMACY:", value: patient.pharmacyPhone),
            second: StringValuePair(label: "FAX:", value: patient.pharmacyFax),
          ),
        ),
      ],
    );
  }

  // Helper row helper to maintain perfect horizontal tabular alignment across fields
  Widget _buildTuple(Tuple tuple) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CarbonTextEdit(label: tuple.first.label, value: tuple.first.value),
        ),
        const SizedBox(width: 8), // Gutter separation between the two columns
        // RIGHT COLUMN (Second Pair: e.g., CONTACT or PHARMACY)
        Expanded(
          child: CarbonTextEdit(label: tuple.second.label, value: tuple.second.value),
        ),
      ],
    );
  }

  // Standard string parser to separate long sdigits into readable "#### ### ###" blocks
  String _formatPHN(String rawPhn) {
    final clean = rawPhn.replaceAll(RegExp(r'\s+'), '');
    if (clean.length == 10) {
      return "${clean.substring(0, 4)} ${clean.substring(4, 7)} ${clean.substring(7)}";
    }
    return rawPhn; // Fallback if format differs
  }
}
