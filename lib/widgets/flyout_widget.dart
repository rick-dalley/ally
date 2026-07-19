import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../classes/carbon_style_constants.dart';
import '../classes/flyable.dart';

class FlyOutItemWidget extends StatelessWidget {
  final Flyable item;
  final double? size;
  final bool? isPrimary;
  final double? borderWidth;
  const FlyOutItemWidget({super.key, required this.item, this.size, this.isPrimary, this.borderWidth});

  @override
  Widget build(BuildContext context) {
    double dim = size ?? CarbonButtonSize.large.height;
    double bWidth = borderWidth ?? 2;
    double iconDim = dim - bWidth;
    bool primary = isPrimary ?? false;

    // Wrap the entire visual area in the GestureDetector here
    return Container(
      color: primary ? item.color : item.onPrimary,
      width: dim,
      height: dim,
      child: Icon(item.icon, size: iconDim, color: primary ? item.onPrimary : item.color),
    );
  }
}

class FlyOutWidget extends StatefulWidget {
  final int selectedItem;
  final List<Flyable> children;
  final CarbonButtonStyle? style;
  final Function(Flyable) onSelected;

  const FlyOutWidget({
    super.key,
    required this.selectedItem,
    required this.onSelected,
    required this.children,
    this.style,
  });

  @override
  FlyOutWidgetState createState() => FlyOutWidgetState();
}

class FlyOutWidgetState extends State<FlyOutWidget> {
  bool _isExpanded = false;

  late List<FlyOutItemWidget> flyoutWidgets;
  late FlyOutItemWidget selectedFlyOutWidget;
  @override
  void initState() {
    super.initState();
    flyoutWidgets = [];
    for (Flyable child in widget.children) {
      flyoutWidgets.add(FlyOutItemWidget(item: child, isPrimary: widget.style == CarbonButtonStyle.primary));
      selectedFlyOutWidget = flyoutWidgets[0];
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
      onLongPress: () => _openDetailedModal(widget.selectedItem),
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
            widget.onSelected(itemWidget.item);
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
      decoration: BoxDecoration(
        color: AppColors.grey.all[0],
        borderRadius: BorderRadius.zero,
        boxShadow: [BoxShadow(color: AppColors.grey.all[6], blurRadius: 2)],
      ),
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
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Icon(item.icon, size: 32, color: item.color),
                  const SizedBox(width: 16),
                  const VerticalDivider(width: 1, thickness: 1),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(item.description, style: Theme.of(context).textTheme.bodyMedium),
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
