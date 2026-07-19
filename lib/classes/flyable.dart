import 'package:flutter/cupertino.dart';

import 'listable.dart';

abstract interface class Flyable implements Listable {
  IconData get icon;
  Color get color;
  Color get onPrimary;
  // String get label;
  // String get description;
  int get index;
}
