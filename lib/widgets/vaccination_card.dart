import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../classes/acuity.dart';
import '../classes/vaccine.dart';

// 1. Add this extension to your file to handle Sentence Case easily
extension StringExtension on String {
  String toSentenceCase() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

// 2. Updated VaccineCard
class VaccineCard extends StatelessWidget {
  final Vaccine vaccine;
  final Function(DateTime, String) onChangedDate;
  final Function(bool, String) onTookVaccine;

  const VaccineCard({super.key, required this.vaccine, required this.onChangedDate, required this.onTookVaccine});

  Future<void> _launchURL(String policyUrl) async {
    final Uri url = Uri.parse(policyUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0), // Carbon spacing token
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)), // Gray 20 equivalent
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: vaccine.taken,
                onChanged: (val) => onTookVaccine(val!, vaccine.name),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vaccine.name.toSentenceCase(),
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF161616), // Carbon text-primary
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vaccine.recommendation,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    color: const Color(0xFF525252), // Carbon text-secondary
                  ),
                ),
                if (vaccine.taken) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text("Taken: ${vaccine.formattedVaccineDate}", style: GoogleFonts.ibmPlexSans(fontSize: 12)),
                      const Spacer(),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () => onChangedDate(vaccine.takenOn!, vaccine.name),
                        icon: const Icon(Symbols.edit, size: 18),
                      ),
                    ],
                  ),
                  Text(
                    vaccine.reminder,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: vaccine.overdue ? const Color(0xFFDA1E28) : const Color(0xFF525252),
                    ),
                  ),
                ],
                if (vaccine.policy.isNotEmpty) CarbonLink(text: "policy", url: vaccine.policy),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CarbonLink extends StatelessWidget {
  final String text;
  final String url;

  const CarbonLink({super.key, required this.text, required this.url});

  Future<void> _launch() async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _launch,
      child: Text(
        text,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 14,
          color: const Color(0xFF0F62FE),
          // IBM Blue (Carbon link-01)
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFF0F62FE),
          decorationThickness: 1.5,
        ),
      ),
    );
  }
}
