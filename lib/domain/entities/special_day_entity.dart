
class SpecialDayEntity {
  final int? id;
  final int employeeId;
  final String kind;
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
    this.kind = 'Birthday',
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

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'employee_id': employeeId,
    'kind': kind,
    'title': title,
    'date': date,
    'yearly': yearly,
    'created_by': createdBy,
    'created_on': createdOn,
    'emp_name': empName,
    'next': next,
    'away': away,
    'years': years,
  };

  factory SpecialDayEntity.fromMap(Map<String, Object?> map) {
    return SpecialDayEntity(
      id: (map['id'] as num?)?.toInt(),
      employeeId: (map['employee_id'] as num?)?.toInt() ?? 0,
      kind: map['kind']?.toString() ?? 'Birthday',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      yearly: (map['yearly'] as num?)?.toInt() ?? 1,
      createdBy: (map['created_by'] as num?)?.toInt(),
      createdOn: map['created_on']?.toString(),
      empName: map['emp_name']?.toString(),
      next: map['next']?.toString(),
      away: (map['away'] as num?)?.toInt(),
      years: (map['years'] as num?)?.toInt(),
    );
  }

  Object? operator [](String key) => toMap()[key];

  String s(String key, [String def = '']) =>
      toMap()[key]?.toString() ?? def;

  int? i(String key) {
    final value = toMap()[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  double d(String key, [double def = 0.0]) {
    final value = toMap()[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? def;
  }
}
