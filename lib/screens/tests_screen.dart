import 'package:flutter/cupertino.dart';

import '../app_theme.dart';
import '../classes/patient.dart';

class TestsScreen extends StatefulWidget {
  final Patient user;
  const TestsScreen({super.key, required this.user});

  @override
  State<StatefulWidget> createState() => TestsScreenState();
}

class TestsScreenState extends State<TestsScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(color: AppTheme.lightTheme.primaryColorLight);
  }
}
