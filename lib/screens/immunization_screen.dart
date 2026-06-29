import 'package:flutter/material.dart';

import '../classes/immunization.dart';
import '../classes/patient.dart';
import '../widgets/vaccination_card.dart';

class ImmunizationScreen extends StatefulWidget {
  final Patient householdMember;
  const ImmunizationScreen({super.key, required this.householdMember});

  @override
  State<StatefulWidget> createState() => ImmunizationScreenState();
}

class ImmunizationScreenState extends State<ImmunizationScreen> {
  // Use a nullable Future to handle the loading state
  Future<void>? _loadingFuture;

  CountrySchedule? _schedule;
  Map<String, PatientVaccine> _takenVaccines = {};

  @override
  void initState() {
    super.initState();
    // Start the loading process
    _loadingFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    // 1. Create the service
    final service = await ImmunizationService.create();

    // 2. Fetch the data and assign to your class-level variables
    final schedule = service.getScheduleForDevice();
    final records = await service.getPatientVaccinations(widget.householdMember.patientUuid);

    // 3. Update the state so the widget knows data is ready
    if (mounted) {
      setState(() {
        _schedule = schedule;
        _takenVaccines = records;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Immunization Schedule")),
      body: FutureBuilder(
        future: _loadingFuture,
        builder: (context, snapshot) {
          // Check if data is still loading
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          // Once done, check if we have the schedule
          if (_schedule == null) return const Center(child: Text("No schedule found."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _schedule!.groups.length,
            itemBuilder: (context, index) {
              final group = _schedule!.groups[index];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Title
                  Text(
                    group.group,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Vaccines List
                  ...group.vaccines.map((v) {
                    final userRecord = _takenVaccines[v.name];
                    return VaccineCard(
                      vaccine: v,
                      onChangedDate: (DateTime p1, String p2) {},
                      onTookVaccine: (bool p1, String p2) {},
                    );
                  }),

                  // Gap between groups
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
