import 'models/stock_alert.dart';

/// Trim, lower-case, and fold Arabic spelling so search is stable
/// across أ/إ/آ, ة/ه, ى/ي, tatweel, and harakat.
String normalize(String value) {
  final buffer = StringBuffer();
  for (final rune in value.trim().toLowerCase().runes) {
    if (rune == 0x0640) {
      continue;
    }
    if (rune >= 0x064B && rune <= 0x0652) {
      continue;
    }
    switch (rune) {
      case 0x0623: // أ
      case 0x0625: // إ
      case 0x0622: // آ
        buffer.writeCharCode(0x0627); // ا
        break;
      case 0x0629: // ة
        buffer.writeCharCode(0x0647); // ه
        break;
      case 0x0649: // ى
        buffer.writeCharCode(0x064A); // ي
        break;
      default:
        buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// Filter, search, and sort for the shift-start alert list.
class AlertRules {
  const AlertRules._();

  static const Map<Severity, int> _severityRank = {
    Severity.critical: 0,
    Severity.high: 1,
    Severity.medium: 2,
    Severity.low: 3,
  };

  static List<StockAlert> apply({
    required Iterable<StockAlert> alerts,
    required Set<Severity> activeFilters,
    required String query,
  }) {
    final needle = normalize(query);
    final matched = <StockAlert>[
      for (final alert in alerts)
        if (_matchesFilter(alert, activeFilters) && _matchesSearch(alert, needle))
          alert,
    ];
    return _sorted(matched);
  }

  static bool _matchesFilter(StockAlert alert, Set<Severity> activeFilters) {
    return activeFilters.isEmpty || activeFilters.contains(alert.severity);
  }

  static bool _matchesSearch(StockAlert alert, String needle) {
    if (needle.isEmpty) {
      return true;
    }
    return normalize(alert.medicineNameEn).contains(needle) ||
        normalize(alert.medicineNameAr).contains(needle);
  }

  static List<StockAlert> _sorted(List<StockAlert> alerts) {
    final indexed = [
      for (var i = 0; i < alerts.length; i++) (i, alerts[i]),
    ];
    indexed.sort((a, b) {
      final byAck = (a.$2.acknowledged ? 1 : 0).compareTo(
        b.$2.acknowledged ? 1 : 0,
      );
      if (byAck != 0) {
        return byAck;
      }
      final bySeverity = _severityRank[a.$2.severity]!.compareTo(
        _severityRank[b.$2.severity]!,
      );
      if (bySeverity != 0) {
        return bySeverity;
      }
      final byCover = a.$2.daysOfCover.compareTo(b.$2.daysOfCover);
      if (byCover != 0) {
        return byCover;
      }
      final byName = a.$2.medicineNameEn.toLowerCase().compareTo(
        b.$2.medicineNameEn.toLowerCase(),
      );
      if (byName != 0) {
        return byName;
      }
      return a.$1.compareTo(b.$1);
    });
    return [for (final item in indexed) item.$2];
  }
}
