import '../../domain/models/stock_alert.dart';

abstract class AlertRepository {
  Future<List<StockAlert>> fetchAlerts();

  Future<void> acknowledge(String id);
}

/// In-memory feed for tests and local development. Head-office HTTP lives in
/// [AlertsApiService] and is not wired this week.
class InMemoryAlertRepository implements AlertRepository {
  InMemoryAlertRepository({
    Iterable<StockAlert>? alerts,
    this.fetchException,
    this.acknowledgeException,
  }) : _alerts = List<StockAlert>.of(alerts ?? sampleAlerts);

  static const List<StockAlert> sampleAlerts = [
    StockAlert(
      id: 'ins-glargine',
      medicineNameEn: 'Insulin Glargine',
      medicineNameAr: 'إنسولين جلارجين',
      severity: Severity.critical,
      daysOfCover: 1.5,
      branchCode: 'CAI-01',
    ),
    StockAlert(
      id: 'metformin',
      medicineNameEn: 'Metformin',
      medicineNameAr: 'ميتفورمين',
      severity: Severity.high,
      daysOfCover: 4,
      branchCode: 'CAI-01',
    ),
    StockAlert(
      id: 'atorvastatin',
      medicineNameEn: 'Atorvastatin',
      medicineNameAr: 'أتورفاستاتين',
      severity: Severity.medium,
      daysOfCover: 6,
      branchCode: 'CAI-02',
    ),
    StockAlert(
      id: 'amlodipine',
      medicineNameEn: 'Amlodipine',
      medicineNameAr: 'أملوديبين',
      severity: Severity.low,
      daysOfCover: 12,
      branchCode: 'CAI-01',
      acknowledged: true,
    ),
  ];

  final List<StockAlert> _alerts;
  final List<String> _acknowledgeCalls = [];

  Object? fetchException;
  Object? acknowledgeException;

  List<StockAlert> get alerts => List<StockAlert>.unmodifiable(_alerts);

  List<String> get acknowledgeCalls =>
      List<String>.unmodifiable(_acknowledgeCalls);

  @override
  Future<List<StockAlert>> fetchAlerts() async {
    if (fetchException != null) {
      throw fetchException!;
    }
    return List<StockAlert>.of(_alerts);
  }

  @override
  Future<void> acknowledge(String id) async {
    _acknowledgeCalls.add(id);
    if (acknowledgeException != null) {
      throw acknowledgeException!;
    }
    final index = _alerts.indexWhere((alert) => alert.id == id);
    if (index >= 0) {
      _alerts[index] = _alerts[index].copyWith(acknowledged: true);
    }
  }
}
