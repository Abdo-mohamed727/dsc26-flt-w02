import 'package:dsc26_flt_w02/data/repositories/alert_repository.dart';
import 'package:dsc26_flt_w02/domain/alert_rules.dart';
import 'package:dsc26_flt_w02/domain/models/stock_alert.dart';
import 'package:dsc26_flt_w02/main.dart';
import 'package:dsc26_flt_w02/ui/alerts/view_models/alerts_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StockAlert _alert({
  String id = 'a',
  String en = 'Metformin',
  String ar = 'ميتفورمين',
  Severity severity = Severity.medium,
  double days = 3,
  String branch = 'CAI-01',
  bool acknowledged = false,
}) {
  return StockAlert(
    id: id,
    medicineNameEn: en,
    medicineNameAr: ar,
    severity: severity,
    daysOfCover: days,
    branchCode: branch,
    acknowledged: acknowledged,
  );
}

void main() {
  group('StockAlert.fromJson', () {
    test('parses a valid feed row and ignores extra fields', () {
      final alert = StockAlert.fromJson({
        'id': 'ins-1',
        'medicineNameEn': 'Insulin',
        'medicineNameAr': 'إنسولين',
        'severity': 'Critical',
        'daysOfCover': 2,
        'branchCode': 'CAI-01',
        'warehouseNote': 'ignore me',
      });

      expect(alert.id, 'ins-1');
      expect(alert.severity, Severity.critical);
      expect(alert.daysOfCover, 2.0);
      expect(alert.acknowledged, isFalse);
    });

    test('accepts case-insensitive severity and double daysOfCover', () {
      final alert = StockAlert.fromJson({
        'id': 'x',
        'medicineNameEn': 'A',
        'medicineNameAr': 'ب',
        'severity': 'LOW',
        'daysOfCover': 1.5,
        'branchCode': 'B',
        'acknowledged': true,
      });
      expect(alert.severity, Severity.low);
      expect(alert.daysOfCover, 1.5);
      expect(alert.acknowledged, isTrue);
    });

    test('throws FormatException for empty strings and non-string severity', () {
      expect(
        () => StockAlert.fromJson({
          'id': '',
          'medicineNameEn': 'A',
          'medicineNameAr': 'ب',
          'severity': 'high',
          'daysOfCover': 1,
          'branchCode': 'B',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => StockAlert.fromJson({
          'id': 'x',
          'medicineNameEn': 'A',
          'medicineNameAr': 'ب',
          'severity': 1,
          'daysOfCover': 1,
          'branchCode': 'B',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('copyWith and value equality cover all fields', () {
      final original = _alert();
      final copy = original.copyWith(acknowledged: true);
      expect(copy.acknowledged, isTrue);
      expect(original.acknowledged, isFalse);
      expect(original, _alert());
      expect(original.hashCode, _alert().hashCode);
      expect(copy, isNot(original));
    });
  });

  group('AlertRules', () {
    test('normalize folds Arabic letters, harakat, and tatweel', () {
      expect(normalize('  إنْسُولـين  '), 'انسولين');
      expect(normalize('أإآ'), 'ااا');
      expect(normalize('مدرسة'), 'مدرسه');
      expect(normalize('على'), 'علي');
    });

    test('sort is stable, does not mutate input, and ignores branch in search', () {
      final first = _alert(id: 'first', en: 'Same');
      final second = _alert(id: 'second', en: 'same');
      final input = [second, first];
      final snapshot = List<StockAlert>.of(input);

      final sorted = AlertRules.apply(
        alerts: input,
        activeFilters: {},
        query: '',
      );
      expect(sorted.map((a) => a.id).toList(), ['second', 'first']);
      expect(input, snapshot);

      expect(
        AlertRules.apply(
          alerts: [_alert(id: 'x', branch: 'CAI-01')],
          activeFilters: {},
          query: 'CAI-01',
        ),
        isEmpty,
      );
    });
  });

  group('AlertsViewModel', () {
    late InMemoryAlertRepository repository;
    late AlertsViewModel viewModel;

    setUp(() {
      repository = InMemoryAlertRepository(
        alerts: [
          _alert(
            id: 'low',
            en: 'Zinc',
            severity: Severity.low,
            days: 2,
          ),
          _alert(
            id: 'crit-ack',
            en: 'Insulin',
            severity: Severity.critical,
            days: 1,
            acknowledged: true,
          ),
          _alert(
            id: 'crit',
            en: 'Warfarin',
            ar: 'وارفارين',
            severity: Severity.critical,
            days: 1,
            branch: 'ALX-02',
          ),
          _alert(
            id: 'high',
            en: 'Metformin',
            severity: Severity.high,
            days: 0.5,
          ),
        ],
      );
      viewModel = AlertsViewModel(repository: repository);
    });

    tearDown(() => viewModel.dispose());

    test('load fetches, sorts, and exposes an unmodifiable list', () async {
      expect(viewModel.loading, isFalse);
      final pending = viewModel.load();
      expect(viewModel.loading, isTrue);
      await pending;
      expect(viewModel.loading, isFalse);
      expect(viewModel.visibleAlerts.map((a) => a.id).toList(), [
        'crit',
        'high',
        'low',
        'crit-ack',
      ]);
      expect(
        () => viewModel.visibleAlerts.add(_alert(id: 'nope')),
        throwsUnsupportedError,
      );
      expect(
        () => viewModel.visibleAlerts.removeAt(0),
        throwsUnsupportedError,
      );
    });

    test('filters, search, and critical count', () async {
      await viewModel.load();
      expect(viewModel.unacknowledgedCriticalCount, 1);

      viewModel.toggleFilter(Severity.critical);
      expect(viewModel.activeFilters, {Severity.critical});
      expect(viewModel.visibleAlerts.map((a) => a.id).toList(), [
        'crit',
        'crit-ack',
      ]);
      expect(viewModel.unacknowledgedCriticalCount, 1);

      viewModel.setQuery('warf');
      expect(viewModel.visibleAlerts.single.id, 'crit');

      viewModel.setQuery('  وَارْفَارِين  ');
      expect(viewModel.visibleAlerts.single.id, 'crit');

      viewModel.toggleFilter(Severity.critical);
      expect(viewModel.activeFilters, isEmpty);
      viewModel.setQuery('');
      expect(viewModel.visibleAlerts, hasLength(4));
    });

    test('acknowledge is optimistic and skips unknown ids', () async {
      await viewModel.load();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.acknowledge('missing');
      expect(repository.acknowledgeCalls, isEmpty);
      expect(notifications, 0);

      final pending = viewModel.acknowledge('crit');
      expect(repository.acknowledgeCalls, ['crit']);
      expect(
        viewModel.visibleAlerts.firstWhere((a) => a.id == 'crit').acknowledged,
        isTrue,
      );
      expect(viewModel.unacknowledgedCriticalCount, 0);
      expect(notifications, 1);
      await pending;
    });

    test('load failure keeps old data and sets error', () async {
      await viewModel.load();
      repository.fetchException = StateError('feed down');
      await viewModel.load();
      expect(viewModel.error, isA<StateError>());
      expect(viewModel.visibleAlerts, isNotEmpty);
    });
  });

  group('AlertsScreen', () {
    testWidgets('lists alerts, searches, and acknowledges', (tester) async {
      final repository = InMemoryAlertRepository(
        alerts: [
          _alert(id: 'm', en: 'Metformin', severity: Severity.high),
          _alert(id: 'i', en: 'Insulin', severity: Severity.critical),
        ],
      );

      await tester.pumpWidget(NourShelfApp(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('Stock alerts'), findsOneWidget);
      expect(find.text('Metformin'), findsOneWidget);
      expect(find.text('Insulin'), findsOneWidget);
      expect(find.byKey(const Key('unacknowledgedCriticalCount')), findsOneWidget);
      expect(find.text('1'), findsWidgets);

      await tester.enterText(find.byKey(const Key('searchField')), 'insulin');
      await tester.pumpAndSettle();
      expect(find.text('Insulin'), findsOneWidget);
      expect(find.text('Metformin'), findsNothing);

      await tester.enterText(find.byKey(const Key('searchField')), '');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('acknowledge_i')));
      await tester.pumpAndSettle();
      expect(find.text('Looked at'), findsOneWidget);
      expect(repository.acknowledgeCalls, ['i']);
    });
  });
}
