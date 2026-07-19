import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/patient_pain.dart';
import 'carbon_style_button.dart';

class DetailedPainModal extends StatefulWidget {
  final PainLevel initialPain;
  final int initialPainIndex;
  final Function(PainLevel, int) onSave;
  final VoidCallback onCancel;
  const DetailedPainModal({
    super.key,
    required this.initialPain,
    required this.initialPainIndex,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<DetailedPainModal> createState() => DetailedPainModalState();
}

class DetailedPainModalState extends State<DetailedPainModal> {
  late PainLevel simplePain;
  late int _selectedPainIndex;

  @override
  void initState() {
    super.initState();
    simplePain = widget.initialPain;
    _selectedPainIndex = widget.initialPainIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Remove constraints or set them only as a maximum safety net
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start, // This tells the column to take only as much space as it needs
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("How I feel", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
          ),
          const SizedBox(height: 8),
          Text("Choose the description that most precisely fits the way that you feel."),
          const SizedBox(height: 16),

          Flexible(
            child: ListView.builder(
              shrinkWrap: true, // This is key: it tells the list to size itself to its children
              physics: const ClampingScrollPhysics(), // Ensures it doesn't bounce unnecessarily
              itemCount: PainLevel.values.length,
              itemBuilder: (context, index) {
                final s = PainLevel.values[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: PainLevelRow(
                    pain: s, // Pass the enum
                    selectedPain: simplePain,
                    selectedPainIndex: _selectedPainIndex,
                    onSelectionChanged: (newSentiment, newIndex) {
                      // Parent manages the state update
                      setState(() {
                        simplePain = newSentiment;
                        _selectedPainIndex = newIndex;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: CarbonButton(
                  label: "Cancel",
                  color: Colors.black26,
                  isSecondary: true,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                child: CarbonButton(
                  label: "Save",
                  onPressed: () {
                    widget.onSave(simplePain, _selectedPainIndex);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class PainLevelRow extends StatelessWidget {
  // Can be Stateless now!
  final PainLevel pain; // Pass the actual enum, not just index
  final int selectedPainIndex;
  final PainLevel selectedPain;
  final Function(PainLevel, int) onSelectionChanged; // The Callback

  const PainLevelRow({
    super.key,
    required this.pain,
    required this.selectedPain,
    required this.selectedPainIndex,
    required this.onSelectionChanged,
  });
  @override
  Widget build(BuildContext context) {
    final painIndices = painLevelToDescription[pain]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          color: pain.color.withValues(alpha: 0.2),
          padding: EdgeInsets.only(top: 36.0, bottom: 36.0, left: 16.0, right: 16.0),
          child: pains[pain]!.getIcon(),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: painIndices.map((painIndex) {
              bool isSelected = selectedPain == pain && selectedPainIndex == painIndex;
              return InkWell(
                onTap: () => onSelectionChanged(pain, painIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 20,
                        color: isSelected ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          disabledVeteransPainScaleDescriptions[painIndex],
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? AppColors.peacockBlue : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
