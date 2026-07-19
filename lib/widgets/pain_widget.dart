import 'package:flutter/material.dart';
import 'package:triage/widgets/pain_detail_widget.dart';
import '../app_theme.dart';
import '../classes/patient_pain.dart';

class PainWidget extends StatefulWidget {
  final PainLevel selectedPain;
  final int painScale;
  final Function(PainLevel, int) onSelected;

  const PainWidget({super.key, required this.selectedPain, required this.onSelected, required this.painScale});

  @override
  PainWidgetState createState() => PainWidgetState();
}

class PainWidgetState extends State<PainWidget> {
  bool _isExpanded = false;

  void showPainSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => DetailedPainModal(
        initialPain: widget.selectedPain,
        initialPainIndex: widget.painScale,
        onSave: (newSentiment, newScale) {
          // Logic to update patient sentiment and precision scale
        },
        onCancel: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey.all[0],
        borderRadius: BorderRadius.zero,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _isExpanded ? _buildExpandedView() : [_buildCollapsedView()],
      ),
    );
  }

  // The view when closed: just the selected icon
  Widget _buildCollapsedView() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
          builder: (context) => DetailedPainModal(
            initialPain: widget.selectedPain,
            initialPainIndex: widget.painScale, // Or your logic for existing scale
            onSave: (newSentiment, newScale) {
              setState(() {
                widget.onSelected(newSentiment, newScale);
                // widget.householdMember.sentimentScale = newScale; // If you have this field
              });
            },
            onCancel: () {},
          ),
        );
      },
      child: pains[widget.selectedPain]!.getIcon(),
    );
  }

  // The view when open: list of all options
  List<Widget> _buildExpandedView() {
    return PainLevel.values.map((sentiment) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: GestureDetector(
          onTap: () {
            widget.onSelected(sentiment, sentiment.index * 2);
            setState(() => _isExpanded = false);
          },
          child: pains[sentiment]!.getIcon(),
        ),
      );
    }).toList();
  }
}
