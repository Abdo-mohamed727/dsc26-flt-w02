/// Chronic-medicine stock alert for one Nour pharmacy branch.
enum Severity { critical, high, medium, low }

class StockAlert {
  const StockAlert({
    required this.id,
    required this.medicineNameEn,
    required this.medicineNameAr,
    required this.severity,
    required this.daysOfCover,
    required this.branchCode,
    this.acknowledged = false,
  });

  final String id;
  final String medicineNameEn;
  final String medicineNameAr;
  final Severity severity;
  final double daysOfCover;
  final String branchCode;
  final bool acknowledged;

  factory StockAlert.fromJson(Map<String, Object?> json) {
    return StockAlert(
      id: _nonEmptyString(json, 'id'),
      medicineNameEn: _nonEmptyString(json, 'medicineNameEn'),
      medicineNameAr: _nonEmptyString(json, 'medicineNameAr'),
      severity: _severity(json['severity']),
      daysOfCover: _daysOfCover(json['daysOfCover']),
      branchCode: _nonEmptyString(json, 'branchCode'),
      acknowledged: _acknowledged(json),
    );
  }

  StockAlert copyWith({
    String? id,
    String? medicineNameEn,
    String? medicineNameAr,
    Severity? severity,
    double? daysOfCover,
    String? branchCode,
    bool? acknowledged,
  }) {
    return StockAlert(
      id: id ?? this.id,
      medicineNameEn: medicineNameEn ?? this.medicineNameEn,
      medicineNameAr: medicineNameAr ?? this.medicineNameAr,
      severity: severity ?? this.severity,
      daysOfCover: daysOfCover ?? this.daysOfCover,
      branchCode: branchCode ?? this.branchCode,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StockAlert &&
            id == other.id &&
            medicineNameEn == other.medicineNameEn &&
            medicineNameAr == other.medicineNameAr &&
            severity == other.severity &&
            daysOfCover == other.daysOfCover &&
            branchCode == other.branchCode &&
            acknowledged == other.acknowledged;
  }

  @override
  int get hashCode => Object.hash(
    id,
    medicineNameEn,
    medicineNameAr,
    severity,
    daysOfCover,
    branchCode,
    acknowledged,
  );

  static String _nonEmptyString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid or missing "$key": $value');
    }
    return value;
  }

  static Severity _severity(Object? value) {
    if (value is! String) {
      throw FormatException('Invalid severity: $value');
    }
    switch (value.toLowerCase()) {
      case 'critical':
        return Severity.critical;
      case 'high':
        return Severity.high;
      case 'medium':
        return Severity.medium;
      case 'low':
        return Severity.low;
      default:
        throw FormatException('Invalid severity: $value');
    }
  }

  static double _daysOfCover(Object? value) {
    if (value is int) {
      if (value < 0) {
        throw FormatException('Invalid daysOfCover: $value');
      }
      return value.toDouble();
    }
    if (value is double) {
      if (value < 0 || value.isNaN || value.isInfinite) {
        throw FormatException('Invalid daysOfCover: $value');
      }
      return value;
    }
    throw FormatException('Invalid daysOfCover: $value');
  }

  static bool _acknowledged(Map<String, Object?> json) {
    if (!json.containsKey('acknowledged')) {
      return false;
    }
    final value = json['acknowledged'];
    if (value is! bool) {
      throw FormatException('Invalid acknowledged: $value');
    }
    return value;
  }
}
