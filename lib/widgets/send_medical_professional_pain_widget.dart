import 'package:flutter/cupertino.dart';
import 'package:triage/classes/staff.dart';
import 'package:url_launcher/url_launcher.dart';

class SendPainDiagram extends StatefulWidget {
  const SendPainDiagram({super.key});

  @override
  State<StatefulWidget> createState() => SendPainDiagramState();
}

class SendPainDiagramState extends State<SendPainDiagram> {
  late List<StaffMember> supportTeam;
  Future<void> sendDoctorEmail({
    required StaffMember staffMember,
    required String bodyPart,
    required String symptoms,
    required String frequency,
  }) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: staffMember.email,
      queryParameters: {
        'subject': 'Recent occurrence of pain c/o doctor ${staffMember.firstName} ${staffMember.lastName}',
        'body':
            'Hi doctor ${staffMember.lastName}.\n\n'
            'I recently began experiencing pain in my $bodyPart. '
            'It feels $symptoms and recurs $frequency. '
            'I would like to make an appointment with you to seek some help for these symptoms.',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      // Handle error: show a SnackBar or Dialog
      throw 'Could not launch email client';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 16);
  }
}
