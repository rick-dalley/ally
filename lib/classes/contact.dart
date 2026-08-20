import 'package:ally/classes/phone.dart';
import 'package:ally/classes/social_media.dart';

import 'contactable.dart';

enum EmailTypes { office, personal }

class Contact implements Contactable {
  final String name;
  @override
  final String email;
  Map<EmailTypes, String> emails = {};
  @override
  final Phone phone;
  Map<PhoneTypes, Phone> phones = {};
  final String? url;
  Map<String, Social>? socialMediaSites;

  Contact({required this.name, required this.email, required this.phone, this.socialMediaSites, this.url})
    : emails = {},
      phones = {};

  static Contact? copy(Contact? contact) {
    if (contact != null) {
      Contact newContact = Contact(
        name: contact.name,
        email: contact.email,
        phone: contact.phone,
        socialMediaSites: contact.socialMediaSites,
        url: contact.url,
      );
      newContact.emails = contact.emails;
      newContact.phones = contact.phones;
      return newContact;
    } else {
      return null;
    }
  }

  factory Contact.fromMap(Map<String, dynamic> item) {
    return Contact(name: item['name'], email: item['email'], phone: item['phone']);
  }

  void addPhone(PhoneTypes phoneType, Phone phone) {
    phones[phoneType] = phone;
  }

  void addEmail(EmailTypes emailType, String email) {
    emails[emailType] = email;
  }

  Phone? getAvailablePhone({required PhoneTypes preferred}) {
    Phone? fallbackPhone;
    Phone? preferredPhone;
    for (var entry in phones.entries) {
      final key = entry.key;
      final value = entry.value;

      // Capture the first non-null phone as a fallback
      fallbackPhone ??= value;

      // Check if this matches the preferred type
      if (key == preferred) {
        preferredPhone = value;
      }
    }

    // Return preferred if found, otherwise fall back to the first available non-null phone
    return preferredPhone ?? fallbackPhone;
  }

  String? getEmail({required EmailTypes emailType}) {
    String? email;
    email = emails[emailType];
    return email;
  }

  String? getPhoneNumber({required PhoneTypes phoneType}) {
    String? phone = '';
    if (phones.isNotEmpty) {
      phone = phones[phoneType]?.number;
    }
    return phone;
  }

  @override
  String toString() => '$name: ${phone.number}';
}
