import 'package:carbon_ui/interfaces/listable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// How a suggestion was arrived at. Surfaced so a caller can treat a confident exact
/// hit differently from a shape-based guess if it ever wants to.
enum DrugMatchKind { exact, prefix, contains, fuzzy }

class DrugNameSuggestion implements Listable {
  final String name;
  final double score; // 0..1, higher is a closer match
  final DrugMatchKind kind;

  const DrugNameSuggestion({required this.name, required this.score, required this.kind});

  @override
  String get label => name;

  // Nothing useful to add under the name in a suggestion list — the drug name is the
  // whole message, and a score or a match kind would be noise to the person reading it.
  @override
  String get description => '';

  @override
  String toString() => '$name (${kind.name} ${score.toStringAsFixed(2)})';
}

/// Type-ahead over a bundled list of generic (INN) drug names.
///
/// Built for two callers that look different and are the same problem:
///
///  * someone typing "hydro" who does not want to spell hydrochlorothiazide, and
///  * a label scan that came back with "HYDROCHLOROT" because the rest of the word
///    wrapped around the far side of the bottle.
///
/// Both are a partial string that needs resolving against a known vocabulary, so both
/// go through [suggest]. That is what makes a fragment useful: a fragment is only
/// worthless when there is nothing to match it against.
class DrugNameMatcher {
  static const String assetPath = 'assets/medications/drug_names.txt';

  final List<String> _display = [];
  final List<String> _normalized = [];

  bool get isLoaded => _display.isNotEmpty;
  int get size => _display.length;

  /// Reads the bundled vocabulary. Safe to call more than once; later calls replace
  /// the contents rather than appending.
  Future<void> load({AssetBundle? bundle}) async {
    final String raw = await (bundle ?? rootBundle).loadString(assetPath);
    loadFromLines(raw.split('\n'));
  }

  /// Split out from [load] so the matcher can be exercised without an asset bundle,
  /// and so a longer vocabulary can be dropped in from anywhere later.
  void loadFromLines(Iterable<String> lines) {
    _display.clear();
    _normalized.clear();
    for (final String line in lines) {
      final String trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      _display.add(_titleCase(trimmed));
      _normalized.add(_normalize(trimmed));
    }
  }

  /// Closest names to [query], best first. Empty when the query is too short to mean
  /// anything — two characters matches most of the list and is just noise.
  List<DrugNameSuggestion> suggest(String query, {int limit = 8}) {
    final String q = _normalize(query);
    if (q.length < 3) return const [];

    final int threshold = q.length <= 4 ? 1 : (q.length <= 8 ? 2 : 3);
    final List<DrugNameSuggestion> hits = [];

    for (int i = 0; i < _normalized.length; i++) {
      final String candidate = _normalized[i];
      final DrugNameSuggestion? hit = _score(q, candidate, _display[i], threshold);
      if (hit != null) hits.add(hit);
    }

    hits.sort((a, b) {
      final int byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.name.compareTo(b.name);
    });

    return hits.length > limit ? hits.sublist(0, limit) : hits;
  }

  /// Best drug-name candidates across every line OCR returned from a label.
  ///
  /// This is what makes a scan useful. Reading a label is not a parsing problem —
  /// layouts vary by pharmacy and by country and there is no grammar to lean on — but
  /// it IS a vocabulary problem: somewhere in those lines is a string that resolves to
  /// a known drug, and the rest is address, prescriber and pharmacy furniture that
  /// resolves to nothing. So every line, and every word within it, gets offered to the
  /// vocabulary, and whatever the vocabulary recognises is what comes back.
  ///
  /// Words are tried as well as whole lines because the name usually shares its line
  /// with the strength and the form ("HYDROCHLOROT 25 MG TABLET"), and the fragment
  /// that identifies the drug is one token of it.
  List<DrugNameSuggestion> suggestFromLines(Iterable<String> lines, {int limit = 6}) {
    final Map<String, DrugNameSuggestion> best = {};

    for (final String line in lines) {
      final List<String> tokens = [line, ...line.split(RegExp(r'[\s,/()\-]+'))];
      for (final String token in tokens) {
        // Four characters before a line-derived token is taken seriously. Three is
        // fine when a person types it deliberately; off a label it would let "TAB",
        // "MAR" and every other scrap of packaging furniture nominate a drug.
        if (token.trim().length < 4) continue;
        for (final DrugNameSuggestion hit in suggest(token, limit: 3)) {
          final DrugNameSuggestion? existing = best[hit.name];
          if (existing == null || hit.score > existing.score) best[hit.name] = hit;
        }
      }
    }

    final List<DrugNameSuggestion> ranked = best.values.toList()
      ..sort((a, b) {
        final int byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : a.name.compareTo(b.name);
      });

    return ranked.length > limit ? ranked.sublist(0, limit) : ranked;
  }

  DrugNameSuggestion? _score(String q, String candidate, String display, int threshold) {
    if (candidate == q) {
      return DrugNameSuggestion(name: display, score: 1, kind: DrugMatchKind.exact);
    }

    // Every prefix match scores the same, and ties break alphabetically below.
    //
    // An earlier version ranked shorter names higher, on the theory that a shorter
    // candidate assumes less of the word. That is backwards for what this is for:
    // typing "hydro" pushed Hydrochlorothiazide BELOW Hydromorphone and
    // Hydrocortisone, burying the one name in the list nobody wants to spell — and,
    // being third, it fell outside the dropdown's visible height. Length is a bad
    // proxy for likelihood. Without real dispensing-frequency data, alphabetical is
    // the honest ordering: predictable, stable, and not quietly biased against the
    // long names this feature exists to save people from typing.
    if (candidate.startsWith(q)) {
      return DrugNameSuggestion(name: display, score: 0.90, kind: DrugMatchKind.prefix);
    }

    if (candidate.contains(q)) {
      return DrugNameSuggestion(name: display, score: 0.70, kind: DrugMatchKind.contains);
    }

    // Nothing lines up exactly, so allow for characters being wrong as well as
    // missing. A truncated fragment is compared against the candidate's prefix of the
    // same length rather than the whole name — otherwise every long drug name would
    // score as hopelessly distant from a short fragment, and truncation plus a
    // misread character (the usual case off a curved label) would never resolve.
    final String comparable = candidate.length > q.length ? candidate.substring(0, q.length) : candidate;
    final int distance = _editDistance(q, comparable, threshold);
    if (distance > threshold) return null;

    final double closeness = 1 - (distance / (threshold + 1));
    final double covered = q.length / candidate.length;
    return DrugNameSuggestion(
      name: display,
      // Coverage still counts here, unlike in the prefix tier: for an inexact match,
      // a fragment accounting for most of the candidate really is a better bet than
      // one accounting for a fifth of it.
      score: (0.30 + (0.25 * closeness)) - (0.10 * (1 - covered)),
      kind: DrugMatchKind.fuzzy,
    );
  }

  /// Levenshtein distance, abandoned as soon as it is certain to exceed [maxAllowed]
  /// so that a long vocabulary does not pay for comparisons it will discard.
  static int _editDistance(String a, String b, int maxAllowed) {
    if ((a.length - b.length).abs() > maxAllowed) return maxAllowed + 1;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> previous = List<int>.generate(b.length + 1, (i) => i);
    List<int> current = List<int>.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      current[0] = i;
      int rowBest = current[0];
      for (int j = 1; j <= b.length; j++) {
        final int substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
        final int deletion = previous[j] + 1;
        final int insertion = current[j - 1] + 1;
        int best = substitution < deletion ? substitution : deletion;
        if (insertion < best) best = insertion;
        current[j] = best;
        if (best < rowBest) rowBest = best;
      }
      if (rowBest > maxAllowed) return maxAllowed + 1;
      final List<int> swap = previous;
      previous = current;
      current = swap;
    }

    return previous[b.length];
  }

  /// Characters OCR habitually confuses on a small, curved, low-contrast label. Folded
  /// on both sides, so "HYDR0CHL0R0T" and "hydrochlorot" collapse to the same string
  /// rather than needing an edit-distance allowance each.
  static const Map<String, String> _confusables = {
    '0': 'o',
    '1': 'l',
    '2': 'z',
    '5': 's',
    '6': 'g',
    '8': 'b',
    '|': 'l',
    '!': 'l',
  };

  static String _normalize(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final String character in input.toLowerCase().split('')) {
      final String folded = _confusables[character] ?? character;
      // Spaces, hyphens and punctuation carry no signal here — "acetylsalicylic acid"
      // and "acetylsalicylicacid" are the same drug, however the label set it.
      if (RegExp(r'[a-z]').hasMatch(folded)) buffer.write(folded);
    }
    return buffer.toString();
  }

  static String _titleCase(String input) {
    return input
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

/// One shared instance, loaded once at startup. The vocabulary is read-only and a few
/// tens of KB, so there is nothing to gain from per-screen copies.
final DrugNameMatcher drugNames = DrugNameMatcher();

/// Loads the shared vocabulary, swallowing a missing or malformed asset: a type-ahead
/// that cannot load is a field without suggestions, not a broken app.
Future<void> loadDrugNames() async {
  try {
    await drugNames.load();
  } catch (error) {
    debugPrint('DrugNameMatcher: vocabulary unavailable, type-ahead disabled: $error');
  }
}
