import 'listable.dart';

// What happens if the patient cancels (or fails to give the required notice for) an
// appointment — kept intentionally minimal: just enough to warn before a cancellation,
// not a real billing system.
enum CancellationBillingPolicy implements Listable {
  partial,
  full;

  @override
  String get label => this == CancellationBillingPolicy.partial ? "Partial Billing" : "Full Billing";

  @override
  String get description =>
      this == CancellationBillingPolicy.partial
          ? "A portion of the visit fee may be charged."
          : "The full visit fee may be charged.";
}
