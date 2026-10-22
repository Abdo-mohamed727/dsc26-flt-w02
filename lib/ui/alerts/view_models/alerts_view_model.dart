import 'package:flutter/foundation.dart';

import '../../../data/repositories/alert_repository.dart';
import '../../../domain/alert_rules.dart';
import '../../../domain/models/stock_alert.dart';

class AlertsViewModel extends ChangeNotifier {
  AlertsViewModel({required this._repository});

  final AlertRepository _repository;
  List<StockAlert> _alerts = const [];
  final Set<Severity> _activeFilters = <Severity>{};
  String _query = '';
  bool _loading = false;
  Object? _error;

  bool get loading => _loading;

  Object? get error => _error;

  List<StockAlert> get visibleAlerts {
    return List<StockAlert>.unmodifiable(
      AlertRules.apply(
        alerts: _alerts,
        activeFilters: _activeFilters,
        query: _query,
      ),
    );
  }

  Set<Severity> get activeFilters => Set<Severity>.unmodifiable(_activeFilters);

  int get unacknowledgedCriticalCount {
    var count = 0;
    for (final alert in _alerts) {
      if (alert.severity == Severity.critical && !alert.acknowledged) {
        count++;
      }
    }
    return count;
  }

  Future<void> load() async {
    if (!_loading) {
      _loading = true;
      notifyListeners();
    }
    try {
      _alerts = List<StockAlert>.of(await _repository.fetchAlerts());
      _error = null;
    } catch (error) {
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void toggleFilter(Severity s) {
    if (!_activeFilters.add(s)) {
      _activeFilters.remove(s);
    }
    notifyListeners();
  }

  void setQuery(String q) {
    final next = q.trim();
    if (next == _query) {
      return;
    }
    _query = next;
    notifyListeners();
  }

  Future<void> acknowledge(String id) async {
    final index = _alerts.indexWhere((alert) => alert.id == id);
    if (index < 0) {
      return;
    }

    await _repository.acknowledge(id);
    final currentIndex = _alerts.indexWhere((alert) => alert.id == id);
    if (currentIndex < 0) {
      return;
    }

    final current = _alerts[currentIndex];
    if (!current.acknowledged) {
      _alerts = [
        for (var i = 0; i < _alerts.length; i++)
          if (i == currentIndex)
            current.copyWith(acknowledged: true)
          else
            _alerts[i],
      ];
      notifyListeners();
    }
  }
}
