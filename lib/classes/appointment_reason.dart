// Common reasons for booking an appointment, offered as quick-pick checkboxes so
// booking doesn't require typing a reason from scratch every time. Not exhaustive —
// free-text notes on the booking sheet cover anything these don't.
enum AppointmentReasonPreset { regularCheckup, followUp, newSymptom, prescriptionRenewal, testResultsReview, referral }

extension AppointmentReasonPresetLabel on AppointmentReasonPreset {
  String get label {
    switch (this) {
      case AppointmentReasonPreset.regularCheckup:
        return "Regular Checkup";
      case AppointmentReasonPreset.followUp:
        return "Follow-up";
      case AppointmentReasonPreset.newSymptom:
        return "New Symptom";
      case AppointmentReasonPreset.prescriptionRenewal:
        return "Prescription Renewal";
      case AppointmentReasonPreset.testResultsReview:
        return "Test Results Review";
      case AppointmentReasonPreset.referral:
        return "Referral";
    }
  }
}
