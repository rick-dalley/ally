// Anything the patient can opt to have pushed to a paired wearable — today that's a
// physician's care order (see care_order.dart), but the shape is deliberately generic
// (title/detail, not order-specific fields) so a reminder or a symptom check-in could
// implement this later without a new sync mechanism. wearableSyncEnabled is the
// patient's own toggle, stored per-item, not a blanket on/off — a physical therapy
// order might be worth a wearable buzz; a diet order probably isn't.
abstract class Notifiable {
  String get notifiableId;
  String get title;
  String get detail;
  bool get wearableSyncEnabled;
}
