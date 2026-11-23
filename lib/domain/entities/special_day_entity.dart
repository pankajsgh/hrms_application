
class SpecialDayEntity {
  final int? id;
  final int employeeId;
  final String title;
  final String date;
  final int yearly;
  final int? createdBy;
  final String? createdOn;
  final String? empName;
  final String? next;
  final int? away;
  final int? years;

  const SpecialDayEntity({
    this.id,
    required this.employeeId,
    required this.title,
    required this.date,
    this.yearly = 1,
    this.createdBy,
    this.createdOn,
    this.empName,
    this.next,
    this.away,
    this.years,
  });

  // Convert entity into Map
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'employee_id': employeeId,
    'title': title,
    'date': date,
    'yearly': yearly,
    'created_by': createdBy,
    'created_on': createdOn,

    // Joined employee and upcoming special day fields
    'emp_name': empName,
    'next': next,
    'away': away,
    'years': years,
  };

  // Convert Map into entity
  factory SpecialDayEntity.fromMap(Map<String, Object?> map) {
    return SpecialDayEntity(
      id: (map['id'] as num?)?.toInt(),
      employeeId: (map['employee_id'] as num?)?.toInt() ?? 0,
      title: (map['title'] ?? '').toString(),
      date: (map['date'] ?? '').toString(),
      yearly: (map['yearly'] as num?)?.toInt() ?? 1,
      createdBy: (map['created_by'] as num?)?.toInt(),
      createdOn: map['created_on']?.toString(),
      empName: map['emp_name']?.toString(),
      next: map['next']?.toString(),
      away: (map['away'] as num?)?.toInt(),
      years: (map['years'] as num?)?.toInt(),
    );
  }

  // Access values using entity['key']
  Object? operator [](String key) => toMap()[key];

  // Get String value
  String s(String key, [String def = '']) {
    return toMap()[key]?.toString() ?? def;
  }

  // Get int value
  int? i(String key) {
    final val = toMap()[key];

    if (val is int) return val;
    if (val is num) return val.toInt();

    return int.tryParse(val?.toString() ?? '');
  }

  // Get double value
  double d(String key, [double def = 0.0]) {
    final val = toMap()[key];

    if (val is double) return val;
    if (val is num) return val.toDouble();

    return double.tryParse(val?.toString() ?? '') ?? def;
  }
}
