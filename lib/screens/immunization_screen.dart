import 'package:flutter/material.dart';
import 'package:triage/classes/date_time_utilities.dart';

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
  late ImmunizationService service;
  CountrySchedule? _schedule;
  Map<String, PatientVaccine> _takenVaccines = {};
  late String memberId;
  @override
  void initState() {
    super.initState();
    // Start the loading process
    memberId = widget.householdMember.patientUuid;
    _loadingFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    service = await ImmunizationService.create();
    final schedule = service.getScheduleForDevice();
    final records = await service.getPatientVaccinations(memberId);

    // 3. Update the state so the widget knows data is ready
    if (mounted) {
      setState(() {
        _schedule = schedule;
        _takenVaccines = records;
        if (_schedule != null) {
          service.resolvePatientImmunizations(_takenVaccines, _schedule!);
        }
      });
    }
  }

  Future<void> onChangedDateHandler(DateTime takenOn, Vaccine v, PatientVaccine pv) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: takenOn,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        v.takenOn = picked;
        pv.received = picked;
      });
    }
  }

  Future<void> onTookVaccineHandler({
    required Vaccine vax,
    required bool taken,
    required DateTime when,
    required String name,
    required String protection,
  }) async {
    setState(() {
      DateTime when = DateTime.now();
      vax.taken = taken;
      vax.takenOn = when;
      int yearsAgo = DTUtilities.calculateYearsSince(when);
      if (taken) {
        _takenVaccines[name] = PatientVaccine(name: name, protection: protection, received: when, yearsAgo: yearsAgo);
        service.insertVaccination(memberId, name, protection, when);
      } else {
        service.deleteVaccination(name, memberId);
      }
    });
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
                      onChangedDate: (DateTime when, String vaccineName) {
                        setState(() {
                          PatientVaccine? pv = _takenVaccines[vaccineName];
                          if (pv != null) {
                            onChangedDateHandler(when, v, pv);
                          }
                        });
                      },
                      onTookVaccine: (String vaccineName, bool taken, String protection, DateTime when) {
                        onTookVaccineHandler(
                          vax: v,
                          taken: taken,
                          when: when,
                          name: vaccineName,
                          protection: protection,
                        );
                      },
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
