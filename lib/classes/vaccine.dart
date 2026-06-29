import 'package:intl/intl.dart';

class Vaccine {
  final String name;
  final String recommendation;
  DateTime? takenOn;
  int yearsAgo;
  String patientUuid;
  int interval;
  String policy;
  bool taken;

  Vaccine({
    required this.name,
    required this.recommendation,
    this.yearsAgo = 0,
    this.patientUuid = "",
    this.taken = false,
    this.takenOn,
    this.policy = "",
    this.interval = 1,
  });

  factory Vaccine.fromMap(Map<String, dynamic> item) {
    return Vaccine(name: item["name"], recommendation: item["recommendation"]);
  }
  DateTime? get expirationDate {
    return takenOn != null ? DateTime(takenOn!.year + interval, takenOn!.month, takenOn!.day) : null;
  }

  int get yearsSince {
    return takenOn != null ? DateTime.now().year - takenOn!.year : 0;
  }

  String get formattedVaccineDate {
    return takenOn == null ? "" : DateFormat('MMMM d, y').format(takenOn!);
  }

  String get formattedExpirationDate {
    return takenOn == null ? "" : DateFormat('MMMM d, y').format(expirationDate!);
  }

  String get reminder {
    int yrs = yearsSince;
    String rem = yrs > 1 ? "($yrs years ago)." : "($yrs year ago).";

    rem = overdue
        ? interval > 1
              ? "$rem\nIt is recommended to take this vaccine every $interval year(s)."
              : "It is recommended to take this vaccine every year."
        : "$rem\nNext vaccination on:$formattedExpirationDate.";
    return rem;
  }

  bool get overdue {
    // Only check if it was actually taken
    if (!taken || takenOn == null) return false;
    DateTime? expDate = expirationDate;
    // It is overdue if the expiration date is before today
    return expDate == null ? false : expDate.isBefore(DateTime.now());
  }
}
