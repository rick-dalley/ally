import 'package:flutter/material.dart';

class AllyWizard extends StatefulWidget {
  final List<Widget> steps; // The capture widgets
  final VoidCallback onExit;

  const AllyWizard({super.key, required this.steps, required this.onExit});

  @override
  AllyWizardState createState() => AllyWizardState();
}

class AllyWizardState extends State<AllyWizard> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  void _nextStep() {
    if (_currentIndex < widget.steps.length - 1) {
      _controller.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousStep() {
    if (_currentIndex > 0) {
      _controller.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Breadcrumb Trail
        _buildBreadcrumbs(),

        // Capture Widget Area
        Expanded(
          child: PageView(
            controller: _controller,
            physics: NeverScrollableScrollPhysics(), // Disables swipe
            onPageChanged: (index) => setState(() => _currentIndex = index),
            children: widget.steps,
          ),
        ),

        // Navigation Bar
        _buildNavBar(),
      ],
    );
  }

  Widget _buildBreadcrumbs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.steps.length, (index) {
        return Container(
          margin: EdgeInsets.all(4),
          height: 8,
          width: index <= _currentIndex ? 24 : 8,
          decoration: BoxDecoration(
            color: index <= _currentIndex ? Colors.blue : Colors.grey,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNavBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: widget.onExit, child: Text("Exit")),
          Row(
            children: [
              if (_currentIndex > 0) IconButton(icon: Icon(Icons.arrow_back), onPressed: _previousStep),
              ElevatedButton(
                onPressed: _nextStep,
                child: Text(_currentIndex == widget.steps.length - 1 ? "Finish" : "Next"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
