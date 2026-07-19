import 'package:flutter/cupertino.dart';

abstract interface class Flyable {
  IconData get icon;
  Color get color;
  Color get onPrimary;
  String get label;
  String get description;
  int get index;
}
