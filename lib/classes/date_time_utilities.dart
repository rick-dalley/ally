import 'dart:math';

import 'package:flutter/cupertino.dart';

class DTUtilities {
  static String getRecencyString(DateTime pastDate) {
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(pastDate);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} minutes ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} hours ago";
    } else if (diff.inDays < 7) {
      return "${diff.inDays} days ago";
    } else if (diff.inDays < 30) {
      int weeks = diff.inDays ~/ 7;
      int days = diff.inDays % 7;
      return "$weeks weeks and $days days ago";
    } else if (diff.inDays < 365) {
      // 30.44 is the average number of days in a month (365/12)
      double months = diff.inDays / 30.44;
      return "${months.toStringAsFixed(1)} months ago";
    } else {
      double years = diff.inDays / 365.25;
      return "${years.toStringAsFixed(1)} years ago";
    }
  }

  static int calculateYearsSince(DateTime pastDate) {
    final DateTime now = DateTime.now();

    // 1. Get the raw difference in years
    int years = now.year - pastDate.year;

    // 2. Adjust downwards if the anniversary hasn't happened yet this year
    if (now.month < pastDate.month || (now.month == pastDate.month && now.day < pastDate.day)) {
      years--;
    }

    return years;
  }

  static DateTime randomHrsAgo({required int max}) {
    final random = Random();
    int rand = random.nextInt(max) + 1;

    // Capture the result of the subtraction
    return DateTime.now().subtract(Duration(hours: rand));
  }

  static DateTime randomYrsAgo({required int min, required int max}) {
    final random = Random();
    if (min > max) return DateTime.now();

    int rand = random.nextInt(max - min) + min;

    // Capture the result of the subtraction
    return DateTime.now().subtract(Duration(days: rand * 365));
  }

  static DateTime sqliteToDart(dynamic value) {
    if (value == null) return DateTime.now();

    // If SQLite returns a String (e.g., '2026-06-05 16:26:45.000')
    if (value is String) {
      List<String> parts = value.split('/');
      if (parts.length == 3) {
        int month = int.parse(parts[0]);
        int day = int.parse(parts[1]);
        int year = int.parse(parts[2]);

        return DateTime(year, month, day);
      }
    }
    // If you are storing as Unix integers
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }

    // Fallback
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static int dateStringToUnixInt(String dateString) {
    try {
      debugPrint("dateStringToUnixInt(String dateString): $dateString");
      // Expected format: 2026-12-17T19:07:52Z
      // We manually extract the parts to avoid all timezone parsing logic
      int year = int.parse(dateString.substring(0, 4));
      int month = int.parse(dateString.substring(5, 7));
      int day = int.parse(dateString.substring(8, 10));
      int hour = int.parse(dateString.substring(11, 13));
      int min = int.parse(dateString.substring(14, 16));
      int sec = int.parse(dateString.substring(17, 19));

      return DateTime.utc(year, month, day, hour, min, sec).millisecondsSinceEpoch ~/ 1000;
    } catch (e) {
      // Fallback for the slash format
      List<String> parts = dateString.split('/');
      if (parts.length == 3) {
        return DateTime.utc(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1])).millisecondsSinceEpoch ~/
            1000;
      }
      return DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    }
  }

  static DateTime aYearAgo() {
    DateTime now = DateTime.timestamp();

    // 2. Subtract 1 from the year (handles leap years correctly)
    DateTime oneYearAgo = DateTime(now.year - 1, now.month, now.day, now.hour, now.minute, now.second, now.millisecond);
    return oneYearAgo;
  }

  static int aYearAgoAsUnixInt() {
    // 1. Get the current UTC timestamp as a DateTime

    // 3. Convert to Unix timestamp (seconds)
    return aYearAgo().millisecondsSinceEpoch ~/ 1000;
  }

  static int now() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  static DateTime aWhileAgo(int m) {
    DateTime now = DateTime.timestamp();

    // 2. Subtract 1 from the year (handles leap years correctly)
    DateTime aWhileAgo = DateTime(now.year, now.month - m, now.day, now.hour, now.minute, now.second, now.millisecond);
    return aWhileAgo;
  }

  static int aWhileAgoUnixInt(int m) {
    return aWhileAgo(m).millisecondsSinceEpoch ~/ 1000;
  }

  static DateTime aMonthAgo() {
    DateTime now = DateTime.timestamp();
    // Subtract 1 from the month (handles leap years correctly)
    DateTime aMonthAgo = DateTime(now.year, now.month - 1, now.day, now.hour, now.minute, now.second, now.millisecond);
    return aMonthAgo;
  }

  static int aMonthAgoUnixInt() {
    return aMonthAgo().millisecondsSinceEpoch ~/ 1000;
  }

  static DateTime aWeekAgo() {
    DateTime now = DateTime.timestamp();
    // Subtract 1 from the month (handles leap years correctly)
    DateTime aWeekAgo = DateTime(now.year, now.month, now.day - 7, now.hour, now.minute, now.second, now.millisecond);
    return aWeekAgo;
  }

  static int aWeekAgoUnixInt() {
    return aWeekAgo().millisecondsSinceEpoch ~/ 1000;
  }

  static DateTime yesterday() {
    DateTime now = DateTime.timestamp();
    // Subtract 1 from the month (handles leap years correctly)
    DateTime yesterday = DateTime(now.year, now.month, now.day - 1, now.hour, now.minute, now.second, now.millisecond);
    return yesterday;
  }

  static int yesterdayUnixInt() {
    return yesterday().millisecondsSinceEpoch ~/ 1000;
  }
}
