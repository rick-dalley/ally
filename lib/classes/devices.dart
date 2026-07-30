import 'package:uuid/uuid.dart';

import 'database_manager.dart';

class MedicalDevice {
  final String id;
  final String name;
  final String description;
  final String purpose;
  final double price;
  final String link;

  const MedicalDevice({
    required this.id,
    required this.description,
    required this.link,
    required this.name,
    required this.price,
    required this.purpose,
  });

  factory MedicalDevice.named(
    double price, {
    required String description,
    required String link,
    required String name,
    required String purpose,
  }) {
    String newId = Uuid().v4();
    return MedicalDevice(id: newId, description: description, link: link, name: name, price: price, purpose: purpose);
  }
}

class PatientMedicalDevice {
  final String patientUuid;
  final String deviceUuid;
  const PatientMedicalDevice({required this.patientUuid, required this.deviceUuid});
}

class PatientMedicalDevices {
  List<PatientMedicalDevice> list = [];
  void add(PatientMedicalDevice device) {
    list.add(device);
    DatabaseManager().addPatientMedicalDevice(device.deviceUuid, device.patientUuid);
  }

  void delete(PatientMedicalDevice device) {
    list.remove(device);
    DatabaseManager().deletePatientMedicalDevice(device.deviceUuid, device.patientUuid);
  }
}
