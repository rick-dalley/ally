import 'package:flutter/cupertino.dart';

class Social {
  final String name;
  final String uri;
  final IconData? icon;
  final String? iconUri;
  const Social({required this.name, required this.uri, this.icon, this.iconUri});
}
