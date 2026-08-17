import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import 'package:carbon_ui/colors/carbon_color_constants.dart';
import 'package:carbon_ui/colors/carbon_theme_constants.dart';
import '../classes/remindable.dart';
import '../classes/reminder_registry.dart';

// A vertically-scrolling list of what's currently due, shown as a modal sheet
// (floating over the screen, not occupying layout space) rather than an inline strip.
// A vertical list lets horizontal swipe-to-dismiss work cleanly, unlike a horizontal
// strip where the list's own scroll gesture competes with the dismiss gesture.
// HomeScreen shows this automatically whenever ReminderRegistry has anything due; it
// closes itself once everything's been handled.
class ReminderSheet extends StatefulWidget {
  const ReminderSheet({super.key});

  @override
  State<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<ReminderSheet> {
  // Dismissible requires the backing list to drop an item the instant its own dismiss
  // animation finishes — not whenever ReminderRegistry.handleAction's DB write + full
  // registry refresh eventually completes and calls notifyListeners(). Without this,
  // the still-due reminder would still be in `due` for one or more frames after
  // Dismissible already considers itself dismissed, which is exactly what throws "A
  // dismissed Dismissible widget is still part of the tree." This set hides an item
  // immediately and optimistically; the real persistence happens in the background.
  final Set<String> _locallyDismissed = {};

  void _handleDismiss(Remindable reminder, ReminderAction action) {
    setState(() => _locallyDismissed.add(reminder.remindableId));
    ReminderRegistry.instance.handleAction(reminder, action).catchError((Object error, StackTrace stackTrace) {
      debugPrint('[ReminderSheet] handleAction failed: $error\n$stackTrace');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ReminderRegistry.instance,
      builder: (context, _) {
        final List<Remindable> due = ReminderRegistry.instance.due
            .where((r) => !_locallyDismissed.contains(r.remindableId))
            .toList();

        if (due.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) Navigator.pop(context);
          });
          return const SizedBox.shrink();
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.onPrimaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(10)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Reminders", style: CarbonTheme.carbonHeadingTextStyle),
                        IconButton(
                          icon: const Icon(Symbols.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: due.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          ReminderTile(reminder: due[index], onDismiss: _handleDismiss),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ReminderTile extends StatelessWidget {
  final Remindable reminder;
  final void Function(Remindable reminder, ReminderAction action) onDismiss;
  const ReminderTile({super.key, required this.reminder, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(reminder.remindableId),
      direction: DismissDirection.horizontal,
      // Fired after the dismiss animation finishes, deliberately — running the async
      // action (and the registry refresh/rebuild it triggers) from confirmDismiss
      // instead would change the underlying list while this widget's own removal
      // animation is still in flight, which Flutter doesn't handle cleanly. onDismiss
      // (owned by ReminderSheet) hides this item from the backing list immediately,
      // synchronously — required by Dismissible's own contract — before the actual
      // async persistence runs in the background.
      onDismissed: (direction) {
        final ReminderAction action = direction == DismissDirection.startToEnd
            ? ReminderAction.done
            : ReminderAction.skipped;
        onDismiss(reminder, action);
      },
      background: _swipeBackground(Alignment.centerLeft, isDone: true),
      secondaryBackground: _swipeBackground(Alignment.centerRight, isDone: false),
      child: ListTile(
        onTap: () => _openActionSheet(context),
        leading: Icon(reminder.icon, color: reminder.color),
        title: Text(reminder.title, style: CarbonTheme.carbonLabelTextStyle),
        subtitle: Text(reminder.subtitle, style: CarbonTheme.carbonHelperTextStyle),
        trailing: Text(_relativeLabel(reminder.nextReminder), style: TextStyle(color: AppTheme.defaultHintColor)),
      ),
    );
  }

  // Carbon's semantic success/error colors, not a single tone reused for both swipe
  // directions — a swipe-right (Done) and swipe-left (Skipped) reveal should read as
  // visually distinct, not just carry different icons on identical backgrounds.
  Widget _swipeBackground(Alignment alignment, {required bool isDone}) {
    final Color accent = isDone ? carbonColorSupportSuccess : carbonColorSupportError;
    return Container(
      color: accent.withValues(alpha: 0.15),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(isDone ? Symbols.check : Symbols.cancel, color: accent),
    );
  }

  Future<void> _openActionSheet(BuildContext context) async {
    final ReminderAction? chosen = await showModalBottomSheet<ReminderAction>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(reminder.title, style: CarbonTheme.carbonHeadingTextStyle),
              ),
            ),
            const SizedBox(height: 8),
            for (final action in reminder.availableActions)
              ListTile(
                leading: Icon(action.icon, color: carbonColorIconInterActive),
                title: Text(action.label),
                onTap: () => Navigator.pop(context, action),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (chosen == null || !context.mounted) return;

    if (chosen == ReminderAction.bumped) {
      final DateTime? newTime = await _pickBumpTime(context);
      if (newTime == null) return;
      await ReminderRegistry.instance.handleAction(reminder, chosen, bumpTo: newTime);
    } else {
      await ReminderRegistry.instance.handleAction(reminder, chosen);
    }
  }

  Future<DateTime?> _pickBumpTime(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return null;

    final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _relativeLabel(DateTime when) {
    final Duration diff = when.difference(DateTime.now());
    if (diff.isNegative) {
      final Duration ago = -diff;
      if (ago.inMinutes < 1) return "now";
      if (ago.inHours < 1) return "${ago.inMinutes}m ago";
      return "${ago.inHours}h ago";
    }
    if (diff.inMinutes < 1) return "now";
    if (diff.inHours < 1) return "in ${diff.inMinutes}m";
    if (diff.inHours < 24) return "in ${diff.inHours}h";
    return "${when.month}/${when.day}";
  }
}
