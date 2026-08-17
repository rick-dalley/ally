import 'package:carbon_ui/interfaces/listable.dart';

// Suggestions only, not a closed set — CarbonAutocomplete lets the wizard's relation
// step accept free text (a foster child, a ward, "my neighbor I look after") just as
// readily as picking one of these. Covers the immediate-family cases the mother-with-
// kids use case actually hits most often; anything less common types straight in.
enum FamilyRelation implements Listable {
  spouse,
  partner,
  mother,
  father,
  daughter,
  son,
  sibling,
  grandparent,
  grandchild,
  fosterChild,
  ward,
  other;

  @override
  String get label {
    switch (this) {
      case FamilyRelation.spouse:
        return "Spouse";
      case FamilyRelation.partner:
        return "Partner";
      case FamilyRelation.mother:
        return "Mother";
      case FamilyRelation.father:
        return "Father";
      case FamilyRelation.daughter:
        return "Daughter";
      case FamilyRelation.son:
        return "Son";
      case FamilyRelation.sibling:
        return "Sibling";
      case FamilyRelation.grandparent:
        return "Grandparent";
      case FamilyRelation.grandchild:
        return "Grandchild";
      case FamilyRelation.fosterChild:
        return "Foster Child";
      case FamilyRelation.ward:
        return "Ward";
      case FamilyRelation.other:
        return "Other";
    }
  }

  @override
  String get description => label;
}
