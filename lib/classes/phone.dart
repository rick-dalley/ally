enum PhoneTypes { cell, office, fax, pager, home, other }

extension PhoneTypeLabels on PhoneTypes {
  String get label {
    switch (this) {
      case PhoneTypes.cell:
        return "cell";
      case PhoneTypes.office:
        return "office";
      case PhoneTypes.fax:
        return "fax";
      case PhoneTypes.pager:
        return "pager";
      case PhoneTypes.home:
        return "home";
      case PhoneTypes.other:
        return "other";
    }
  }
}

class Phone {
  final String number;
  final PhoneTypes phoneType;
  bool isMain = false;

  Phone({required this.number, required this.phoneType, required this.isMain});
  factory Phone.fromPhoneNumber(String phoneNumber) {
    return Phone(number: phoneNumber, phoneType: PhoneTypes.office, isMain: true);
  }
}
