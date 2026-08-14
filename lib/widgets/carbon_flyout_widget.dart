import 'package:flutter/material.dart';
import '../classes/carbon_theme_constants.dart';
import '../classes/carbon_color_constants.dart';
import '../classes/flyable.dart';

class CarbonFlyOutItemWidget extends StatelessWidget {
  final Flyable flyableItem;
  final CarbonButtonStyle? style;
  final double? size;
  final double? borderWidth;

  const CarbonFlyOutItemWidget({super.key, required this.flyableItem, this.size, this.borderWidth, this.style});

  @override
  Widget build(BuildContext context) {
    double dim = size ?? CarbonButtons.medium.height;
    double bWidth = borderWidth ?? 2;
    double iconDim = dim - bWidth;

    CarbonButtonStyle buttonStyle = style ?? CarbonButtonStyle.ghost;
    Color fontColor = CarbonTheme.getButtonFontColor(buttonStyle);
    Color backgroundColor = CarbonTheme.getButtonColor(buttonStyle);

    // Wrap the entire visual area in the GestureDetector here
    return Container(
      color: backgroundColor,
      width: dim,
      height: dim,
      child: Icon(flyableItem.icon, size: iconDim, color: fontColor),
    );
  }
}

class CarbonFlyOutWidget extends StatefulWidget {
  final int selectedItem;
  final List<Flyable> children;
  final CarbonButtonStyle? style;
  final Function(Flyable) onSelected;
  // Overrides the default long-press behavior (reopening the same picker list) —
  // e.g. the mood widget uses this to ask "why do you feel this way" instead.
  final VoidCallback? onLongPress;

  const CarbonFlyOutWidget({
    super.key,
    required this.selectedItem,
    required this.onSelected,
    required this.children,
    this.style,
    this.onLongPress,
  });

  @override
  CarbonFlyOutWidgetState createState() => CarbonFlyOutWidgetState();
}

class CarbonFlyOutWidgetState extends State<CarbonFlyOutWidget> {
  bool _isExpanded = false;
  late CarbonButtonStyle buttonStyle;
  late List<CarbonFlyOutItemWidget> flyoutWidgets;
  late CarbonFlyOutItemWidget selectedFlyOutWidget;

  @override
  void initState() {
    super.initState();
    flyoutWidgets = [];
    buttonStyle = widget.style ?? CarbonButtonStyle.ghost;
    for (Flyable child in widget.children) {
      flyoutWidgets.add(CarbonFlyOutItemWidget(flyableItem: child, style: buttonStyle));
    }
    selectedFlyOutWidget = flyoutWidgets[widget.selectedItem];
  }

  // selectedItem can change after the first build — e.g. the mood widget loads the
  // patient's actual current mood asynchronously, arriving after this widget's
  // initial construction. Without this, the icon stays stuck on whatever was selected
  // at construction time even though the parent's own label text updates correctly.
  @override
  void didUpdateWidget(covariant CarbonFlyOutWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedItem != oldWidget.selectedItem) {
      setState(() => selectedFlyOutWidget = flyoutWidgets[widget.selectedItem]);
    }
  }

  void showItemSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => DetailedItemModal(
        items: widget.children,
        onSelected: (Flyable item) {
          setState(() {
            selectedFlyOutWidget = flyoutWidgets[item.index];
          });
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  // The collapsed view: Show the item that matches the current selection
  Widget _buildCollapsed() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      onLongPress: widget.onLongPress ?? () => _openDetailedModal(widget.selectedItem),
      child: selectedFlyOutWidget,
    );
  }

  // The expanded view: Show the full list of widgets
  List<Widget> _buildExpanded() {
    List<Widget> expanded = [];
    for (var itemWidget in flyoutWidgets) {
      expanded.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.onSelected(itemWidget.flyableItem);
            setState(() {
              _isExpanded = false;
              selectedFlyOutWidget = itemWidget;
            });
          },
          child: itemWidget,
        ),
      );
    }
    return expanded;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(color: carbonColorButtonTertiary, borderRadius: BorderRadius.zero),
      child: _isExpanded
          ? Container(
              // This forces the Wrap to only be as wide as the parent allows,
              // triggering the line break when the width is exceeded.
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
              child: Wrap(spacing: 0, runSpacing: 0, children: _buildExpanded()),
            )
          : _buildCollapsed(),
    );
  }

  void _openDetailedModal(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => DetailedItemModal(
        items: widget.children,
        onSelected: (Flyable item) {
          setState(() {
            selectedFlyOutWidget = flyoutWidgets[item.index];
          });
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}

class DetailedItemModal extends StatelessWidget {
  final List<Flyable> items;
  final Function(Flyable) onSelected;
  final VoidCallback onCancel;

  const DetailedItemModal({super.key, required this.items, required this.onSelected, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Sentiment"),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: onCancel),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () {
              onSelected(item);
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(item.icon, size: 24, color: item.color),
                  const SizedBox(width: 16),
                  const VerticalDivider(width: 1, thickness: 1),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: CarbonTheme.carbonTertiaryButtonTextStyle),
                        const SizedBox(height: 4),
                        Text(item.description, style: CarbonTheme.carbonTextStyle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
