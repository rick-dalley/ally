import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_theme_constants.dart';

import '../app_theme.dart';
import '../classes/medication_services.dart';

class InteractionsChip extends StatefulWidget {
  final List<InteractionConflict> interactions;
  final String medicationName;
  const InteractionsChip({super.key, required this.interactions, required this.medicationName});

  @override
  State<InteractionsChip> createState() => InteractionsChipState();
}

class InteractionsChipState extends State<InteractionsChip> {
  // This is where you'll eventually track toggle states
  // bool _isIgnored = false;

  @override
  Widget build(BuildContext context) {
    // Keep the "Blank Row" placeholder for consistency when no problems exist
    if (widget.interactions.isEmpty) {
      return const SizedBox(height: 32);
    }

    final int count = widget.interactions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Badge(
        // The notification badge on the top right
        label: Text('$count'),
        // Only show the count badge if there's more than one interaction
        isLabelVisible: count > 1,
        backgroundColor: Colors.red.shade900,
        largeSize: 18,
        child: ActionChip(
          avatar: Icon(Symbols.join_inner, size: 16, color: AppTheme.onPrimaryColor),
          label: Text(
            count == 1 ? "Interacts with: ${widget.interactions.first.conflicting}" : "Multiple Interactions",
            style: TextStyle(color: AppTheme.onPrimaryColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          shape: StadiumBorder(side: BorderSide(color: Colors.red.shade700)),
          onPressed: () => _showInteractionDetails(context),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  void _showInteractionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
              const SizedBox(width: 10),
              const Text("Interactions Found"),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.interactions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = widget.interactions[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item.interaction),
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close"))],
        );
      },
    );
  }
}

class InteractionTile extends StatelessWidget {
  final String interactsWith;
  final String explanation;
  final TextStyle? style;
  final TextStyle? explanationStyle;
  final Color? backgroundColor;

  const InteractionTile({
    super.key,
    required this.interactsWith,
    required this.explanation,
    this.style,
    this.explanationStyle,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      shape: Border.all(color: Colors.transparent),
      shadowColor: Colors.transparent,
      child: Column(
        children: [
          Align(
            alignment: AlignmentGeometry.centerLeft,
            child: Text(interactsWith, style: style ?? CarbonTheme.carbonTextStyle),
          ),
          Text(explanation, style: explanationStyle ?? CarbonTheme.carbonLabelTextStyle),
        ],
      ),
    );
  }
}
