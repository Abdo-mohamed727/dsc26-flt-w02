first i tell him that is the structure of the project 
lib/
  main.dart                                    
  domain/models/stock_alert.dart               
  data/repositories/alert_repository.dart      
  data/services/alerts_api_service.dart        
  ui/alerts/view_models/alerts_view_model.dart  
  ui/alerts/widgets/alerts_screen.dart       
test/public_test.dart 

then: 

role : you are an intern or junior flutter developer 
Context:
I'm building a Flutter app for  pharmacy branches. At the start of a shift,
each pharmacist sees the stock alerts for their branch: which chronic medicines
are about to run out, how urgent each one is, and which ones they have already
looked at. Head office sends the alerts as a JSON feed. The app is built in
layers (data / domain / UI). The sorting and search rules will change often
so they live in the domain layer and are tested.

Task:
Create `lib/domain/models/stock_alert.dart` with an immutable `StockAlert` class
and a `Severity` enum (critical, high, medium, low).

Fields:
id, medicineNameEn, medicineNameAr, severity, daysOfCover (double),
branchCode, acknowledged (bool, default false).

Implement:
1. `factory StockAlert.fromJson(Map<String, Object?> json)`
   - id, medicineNameEn, medicineNameAr, branchCode: non-empty strings.
   - severity: case-insensitive match ("Critical", "LOW" are fine); a
     non-string value is invalid.
   - daysOfCover: int or double, >= 0, stored as double.
   - acknowledged: optional bool, false when the key is missing.
   - Ignore unknown extra fields.
2. `copyWith` with an optional parameter for every field.
3. `operator ==` and `hashCode` over all seven fields.

Constraints:
- Any invalid input must throw `FormatException`, never `TypeError`
  (no bare `as String` on unchecked values).
- Pure Dart, with no Flutter imports in the domain layer.
- No external packages (no freezed, no equatable).

Output format:
- Only the complete Dart file, with a short doc comment on the class.
- After the code, list any assumption you made, one line each.

after that :
Context:
Flutter app for pharmacy branches. At the start of a shift, a pharmacist
sees their branch's stock alerts (chronic medicines about to run out, how urgent
each is, which ones they already looked at). Head office sends alerts as a JSON
feed. The app is layered (data / domain / UI). Sorting and search rules will
change often, so they must live in one place and be easy to unit test.
`StockAlert` and `Severity` already exist in lib/domain/models/stock_alert.dart
(immutable, with fromJson, copyWith, ==/hashCode). Do not change that file.

Task:
Create two things.

1. The repository
   - lib/domain/repositories/alert_repository.dart: abstract class `AlertRepository`
       Future<List<StockAlert>> fetchAlerts();
       Future<void> acknowledge(String id);
   - lib/data/repositories/fake_alert_repository.dart: in-memory implementation
     for tests and development. It records every call to `acknowledge` (so tests
     can assert "called once") and can be configured to throw.
   - <<FILL IN: real implementation reading the head-office JSON feed (HTTP
     package, endpoint, auth), or say "interface and fake only for now">>

2. The view model: lib/ui/alerts/view_models/alerts_view_model.dart
   `class AlertsViewModel extends ChangeNotifier`, constructor
   `AlertsViewModel({required AlertRepository repository})`.
   Keep these public members exactly:
   - Future<void> load(): fetches from the repository; `loading` is true while it runs.
   - bool get loading
   - List<StockAlert> get visibleAlerts: unmodifiable (add/removeAt throw
     UnsupportedError). Filtered by severity and search, then sorted.
   - Set<Severity> get activeFilters: selected severities; empty means "show all".
     Return an unmodifiable view.
   - void toggleFilter(Severity s): add if absent, remove if present; several
     can be active at once.
   - void setQuery(String q)
   - Future<void> acknowledge(String id): call repository.acknowledge(id) once,
     then replace that alert with copyWith(acknowledged: true) BEFORE the returned
     future completes. Never mutate the original object. Unknown id: no repository
     call and no change.
   - int get unacknowledgedCriticalCount: critical and not acknowledged, counted
     over ALL loaded alerts regardless of current filters and search.

Rules (domain logic, kept in one pure function or class, not spread across the view model):
   - Sort: <<FILL IN, for example: severity (critical first), then daysOfCover
     ascending, then unacknowledged before acknowledged, then medicineNameEn>>
   - Search: <<FILL IN: case-insensitive? matches English name, Arabic name,
     branchCode? trim whitespace? empty query shows all?>>

Constraints:
   - Call notifyListeners() on every state change, and not when nothing changed.
   - load() failure: <<FILL IN: keep old data? expose an `error` field?>>
   - Pure Dart in domain/ and data/, no Flutter imports there. The view model
     imports only package:flutter/foundation.dart.
   - No external packages (no provider, no freezed, no equatable).

Output format:
   - Complete files, one per path.
   - Then a short list of assumptions, one line each.


errors :

it didn't handle search for arabic and sorting by ack so i tell it 
Rules (domain logic, kept in one pure, separately testable place, not inside the
view model). Suggested file: lib/domain/alert_rules.dart

Sort, in this order (each step only breaks ties of the previous one):
   1. unacknowledged before acknowledged
   2. severity: critical, high, medium, low (use an explicit rank, do not
      depend on the enum's declaration order)
   3. daysOfCover ascending
   4. medicineNameEn A-Z, comparing the toLowerCase() strings
   Sorting must not mutate the input list, and must give a deterministic result
   when all four keys are equal (keep the original feed order).

Search:
   An alert matches if the normalised query is a substring of the normalised
   English name OR the normalised Arabic name (medicineNameEn / medicineNameAr).
   Do not search branchCode or id.
   Normalise the query and both names with the SAME function `normalize(String)`:
     - trim
     - toLowerCase()
     - Arabic letters:
         أ  إ  آ  ->  ا
         ة  ->  ه
         ى  ->  ي
     - remove tatweel ـ (U+0640)
     - remove Arabic diacritics U+064B to U+0652 (fathatan, dammatan, kasratan,
       fatha, damma, kasra, shadda, sukun)
   An empty query (after normalising) matches everything.

Combining:
   An alert is visible only if it passes BOTH the severity filter
   (empty activeFilters = all severities) AND the search. Sorting applies to the
   result.
   unacknowledgedCriticalCount ignores filters and search.

acceptance criteria
Sort: unacknowledged first, then critical, high, medium, low, then lower daysOfCover, then name A–Z ignoring case. Ties keep the feed order, and the input list is never mutated.
Normalise: the query and both names go through one normalize (trim, lowercase, أإآ→ا, ة→ه, ى→ي, remove tatweel and U+064B–U+0652), and normalize(normalize(x)) == normalize(x).
Search: a match is a substring of the English or Arabic name, so "اسبرين" matches "أسبرين". Branch code and id are never searched.
Empty query: "", spaces, and tatweel or diacritics alone match everything, and a query with no match gives an empty list.
Combine: an alert shows only if it passes both the severity filter (empty means all) and the search, and unacknowledgedCriticalCount ignores both. 