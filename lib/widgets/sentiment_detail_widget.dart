import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/patient_sentiment.dart';
import 'carbon_style_button.dart';

class DetailedSentimentModal extends StatefulWidget {
  final Sentiment initialSentiment;
  final int initialPainIndex;
  final Function(Sentiment, int) onSave;
  final VoidCallback onCancel;
  const DetailedSentimentModal({
    super.key,
    required this.initialSentiment,
    required this.initialPainIndex,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<DetailedSentimentModal> createState() => DetailedSentimentModalState();
}

class DetailedSentimentModalState extends State<DetailedSentimentModal> {
  late Sentiment _selectedSentiment;
  late int _selectedPainIndex;

  @override
  void initState() {
    super.initState();
    _selectedSentiment = widget.initialSentiment;
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
              itemCount: Sentiment.values.length,
              itemBuilder: (context, index) {
                final s = Sentiment.values[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SentimentRow(
                    sentiment: s, // Pass the enum
                    selectedSentiment: _selectedSentiment,
                    selectedPainIndex: _selectedPainIndex,
                    onSelectionChanged: (newSentiment, newIndex) {
                      // Parent manages the state update
                      setState(() {
                        _selectedSentiment = newSentiment;
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
                    widget.onSave(_selectedSentiment, _selectedPainIndex);
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

class SentimentRow extends StatelessWidget {
  // Can be Stateless now!
  final Sentiment sentiment; // Pass the actual enum, not just index
  final int selectedPainIndex;
  final Sentiment selectedSentiment;
  final Function(Sentiment, int) onSelectionChanged; // The Callback

  const SentimentRow({
    super.key,
    required this.sentiment,
    required this.selectedSentiment,
    required this.selectedPainIndex,
    required this.onSelectionChanged,
  });
  @override
  Widget build(BuildContext context) {
    final painIndices = sentimentToPainMap[sentiment]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          color: sentiment.color.withValues(alpha: 0.2),
          padding: EdgeInsets.only(top: 36.0, bottom: 36.0, left: 16.0, right: 16.0),
          child: patientSentiments[sentiment]!.getIcon(),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: painIndices.map((painIndex) {
              bool isSelected = selectedSentiment == sentiment && selectedPainIndex == painIndex;
              return InkWell(
                onTap: () => onSelectionChanged(sentiment, painIndex),
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
                            color: isSelected ? AppTheme.deepLogicViolet : Colors.black87,
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
