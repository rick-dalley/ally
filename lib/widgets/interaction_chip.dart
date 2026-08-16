import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/carbon_theme_constants.dart';

import '../classes/carbon_color_constants.dart';
import '../classes/medication_services.dart';
import 'carbon_button_compact.dart';

// Carbon-native, replacing the old raw-Material version (ActionChip/Badge/AlertDialog) —
// this is the widget the acknowledge/dismiss ask directly touches, so this is the natural
// moment to bring it in line with AllergyConflictChip's precedent rather than layering new
// behavior onto the old Material styling.
class InteractionsChip extends StatefulWidget {
  final List<InteractionConflict> interactions;
  final String medicationName;
  // Pair keys (InteractionConflict.pairKey) already acknowledged/dismissed for this
  // patient — the source of truth lives in PrescriptionScreenState, loaded from
  // interaction_acknowledgment, so this widget stays a pure function of its props.
  final Set<String> acknowledgedPairs;
  final Set<String> dismissedPairs;
  final Future<void> Function(String medicationA, String medicationB)
  onAcknowledge;
  final Future<void> Function(String medicationA, String medicationB) onDismiss;

  const InteractionsChip({
    super.key,
    required this.interactions,
    required this.medicationName,
    required this.acknowledgedPairs,
    required this.dismissedPairs,
    required this.onAcknowledge,
    required this.onDismiss,
  });

  @override
  State<InteractionsChip> createState() => InteractionsChipState();
}

class InteractionsChipState extends State<InteractionsChip> {
  // Optimistic local overrides so the chip/dialog respond instantly on tap rather than
  // waiting for the DB round trip and the ancestor rebuild it triggers — same
  // "hide/flip immediately, persist in the background" shape used by ReminderSheet.
  final Set<String> _locallyAcknowledged = {};
  final Set<String> _locallyDismissed = {};

  bool _isAcknowledged(InteractionConflict c) =>
      widget.acknowledgedPairs.contains(c.pairKey) ||
      _locallyAcknowledged.contains(c.pairKey);

  bool _isDismissed(InteractionConflict c) =>
      widget.dismissedPairs.contains(c.pairKey) ||
      _locallyDismissed.contains(c.pairKey);

  Future<void> _acknowledge(InteractionConflict c) async {
    setState(() => _locallyAcknowledged.add(c.pairKey));
    try {
      await widget.onAcknowledge(c.primaryMedName, c.conflictingMedName);
    } catch (_) {
      // Best-effort — the optimistic UI already reflects the patient's action; a failed
      // write here just means the next full reload won't have it, not a broken screen.
    }
  }

  Future<void> _dismissAll(List<InteractionConflict> items) async {
    setState(() {
      for (final c in items) {
        _locallyDismissed.add(c.pairKey);
      }
    });
    for (final c in items) {
      try {
        await widget.onDismiss(c.primaryMedName, c.conflictingMedName);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<InteractionConflict> visible = widget.interactions
        .where((c) => !_isDismissed(c))
        .toList();
    if (visible.isEmpty) return const SizedBox(height: 32);

    final bool allAcknowledged = visible.every(_isAcknowledged);
    final int count = visible.length;
    final String label = count == 1
        ? "Interacts with: ${visible.first.conflicting}"
        : "Multiple Interactions ($count)";

    // Unacknowledged: the original "primary" warning look (white on red). Once every
    // interaction on this chip has been acknowledged: red on white with a red frame,
    // per Richard's spec — still visible, but no longer shouting.
    final Color fg = allAcknowledged ? carbonColorSupportError : Colors.white;
    final Color bg = allAcknowledged ? Colors.white : carbonColorSupportError;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () => _showInteractionDetails(context, visible),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: carbonColorSupportError),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.join_inner, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Only offered once every interaction on this chip has actually been
              // acknowledged — dismissing something the patient was never shown/didn't
              // accept isn't an option.
              if (allAcknowledged) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _dismissAll(visible),
                  child: Icon(Symbols.close, size: 14, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showInteractionDetails(
    BuildContext context,
    List<InteractionConflict> items,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Row+Expanded below needs a real bounded width to lay out against — Dialog
            // has no max width of its own, so without this the Row gets squeezed toward
            // zero (text wraps to one character per line) while the un-flexed Acknowledge
            // button still demands its own space and overflows past the resolved edge.
            // Same 85%-clamped sizing already used for the Emergency QR code.
            final double dialogWidth =
                (MediaQuery.of(dialogContext).size.width * 0.85).clamp(
                  280.0,
                  480.0,
                );
            return Dialog(
              shape: const ContinuousRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: SizedBox(
                width: dialogWidth,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Symbols.join_inner,
                            color: carbonColorSupportError,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Interactions Found",
                            style: CarbonTheme.carbonHeadingTextStyle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...items.map((c) {
                        final bool acked = _isAcknowledged(c);
                        final Color boxColor = acked
                            ? carbonColorSupportSuccess
                            : carbonColorSupportError;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: boxColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.description,
                                style: CarbonTheme.carbonLabelTextStyle,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.interaction,
                                style: CarbonTheme.carbonHelperTextStyle,
                              ),
                              const SizedBox(height: 6),
                              // This is a name-pair match, not a clinical review — the
                              // reassurance and the acknowledgment live in the same box
                              // deliberately, so the patient reads both together rather
                              // than acknowledging a warning they haven't actually seen
                              // the caveat for.
                              Text(
                                "This may not be a problem for you — check with your doctor or pharmacist if "
                                "you're unsure.",
                                style:
                                    (CarbonTheme.carbonHelperTextStyle ??
                                            const TextStyle())
                                        .copyWith(fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: acked
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Symbols.check_circle,
                                            color: carbonColorSupportSuccess,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Acknowledged",
                                            style: TextStyle(
                                              color: carbonColorSupportSuccess,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : CarbonCompactButton(
                                        label: "Acknowledge",
                                        icon: Symbols.check,
                                        style: CarbonButtonStyle.secondary,
                                        onTap: () async {
                                          await _acknowledge(c);
                                          setDialogState(() {});
                                        },
                                      ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      CarbonCompactButton(
                        icon: Symbols.check,
                        label: "Close",
                        style: CarbonButtonStyle.primary,
                        onTap: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
            child: Text(
              interactsWith,
              style: style ?? CarbonTheme.carbonTextStyle,
            ),
          ),
          Text(
            explanation,
            style: explanationStyle ?? CarbonTheme.carbonLabelTextStyle,
          ),
        ],
      ),
    );
  }
}
