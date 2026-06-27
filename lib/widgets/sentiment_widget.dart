import 'package:flutter/material.dart';
import '../classes/patient_sentiment.dart';

class SentimentWidget extends StatefulWidget {
  final Sentiment selectedSentiment;
  final int painScale;
  final Function(Sentiment, int) onSelected;

  const SentimentWidget({
    super.key,
    required this.selectedSentiment,
    required this.onSelected,
    required this.painScale,
  });

  @override
  SentimentWidgetState createState() => SentimentWidgetState();
}

class SentimentWidgetState extends State<SentimentWidget> {
  bool _isExpanded = false;

  void showSentimentDetailSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DetailedSentimentModal(
        initialSentiment: widget.selectedSentiment,
        initialPainIndex: widget.painScale,
        onSave: (newSentiment, newScale) {
          // Logic to update patient sentiment and precision scale
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
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
          builder: (context) => DetailedSentimentModal(
            initialSentiment: widget.selectedSentiment,
            initialPainIndex: widget.painScale, // Or your logic for existing scale
            onSave: (newSentiment, newScale) {
              setState(() {
                widget.onSelected(newSentiment, newScale);
                // widget.householdMember.sentimentScale = newScale; // If you have this field
              });
            },
          ),
        );
      },
      child: patientSentiments[widget.selectedSentiment]!.getIcon(),
    );
  }

  // The view when open: list of all options
  List<Widget> _buildExpandedView() {
    return Sentiment.values.map((sentiment) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GestureDetector(
          onTap: () {
            widget.onSelected(sentiment, sentiment.index * 2);
            setState(() => _isExpanded = false);
          },
          child: patientSentiments[sentiment]!.getIcon(),
        ),
      );
    }).toList();
  }
}

class DetailedSentimentModal extends StatefulWidget {
  final Sentiment initialSentiment;
  final int initialPainIndex;
  final Function(Sentiment, int) onSave;

  const DetailedSentimentModal({
    super.key,
    required this.initialSentiment,
    required this.initialPainIndex,
    required this.onSave,
  });

  @override
  State<DetailedSentimentModal> createState() => _DetailedSentimentModalState();
}

class _DetailedSentimentModalState extends State<DetailedSentimentModal> {
  final Map<Sentiment, List<int>> _sentimentToPainMap = {
    Sentiment.happy: [0],
    Sentiment.content: [1, 2],
    Sentiment.neutral: [3, 4],
    Sentiment.dissatisfied: [5, 6],
    Sentiment.sad: [7, 8],
    Sentiment.stressed: [9, 10],
  };

  final List<String> disabledVeteransPainScaleDescriptions = [
    "0: No pain. Feels normal.",
    "1: Hardly noticeable.",
    "2: Noticeable/distracting, but can do daily activities.",
    "3: Distressing/distracting, but can do daily activities.",
    "4: Strong, life-interrupting. I need to stop.",
    "5: Strong, life-limiting. Cannot do daily activities.",
    "6: Strong, life-limiting. Struggling to concentrate.",
    "7: Severe, life-limiting. Cannot engage in any activity.",
    "8: Intense, life-limiting. Unable to function.",
    "9: Intense, life-limiting. Bed-bound.",
    "10: As bad as it could be. Nothing else matters.",
  ];

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
      padding: const EdgeInsets.all(20),
      // Remove constraints or set them only as a maximum safety net
      child: Column(
        mainAxisSize: MainAxisSize.min, // This tells the column to take only as much space as it needs
        children: [
          const Text("Clinical Assessment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // REMOVED: Expanded
          // Use Flexible to allow the ListView to size itself within the Column
          Flexible(
            child: ListView.builder(
              shrinkWrap: true, // This is key: it tells the list to size itself to its children
              physics: const ClampingScrollPhysics(), // Ensures it doesn't bounce unnecessarily
              itemCount: Sentiment.values.length,
              itemBuilder: (context, sentimentIndex) {
                final s = Sentiment.values[sentimentIndex];
                final painIndices = _sentimentToPainMap[s]!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 8.0), child: patientSentiments[s]!.getIcon()),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: painIndices.map((painIndex) {
                            bool isSelected = _selectedSentiment == s && _selectedPainIndex == painIndex;
                            return InkWell(
                              onTap: () => setState(() {
                                _selectedSentiment = s;
                                _selectedPainIndex = painIndex;
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                      size: 18,
                                      color: isSelected ? Colors.blue : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        disabledVeteransPainScaleDescriptions[painIndex],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isSelected ? Colors.blue : Colors.black87,
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
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            onPressed: () {
              widget.onSave(_selectedSentiment, _selectedPainIndex);
              Navigator.pop(context);
            },
            child: const Text("Save Assessment"),
          ),
        ],
      ),
    );
  }
}
