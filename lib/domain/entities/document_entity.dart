
class DocumentEntity {
  final int? id;
  final int employeeId;
  final String title;
  final String category;
  final String filePath;
  final String addedOn;
  final String? empName;

  const DocumentEntity({
    this.id,
    required this.employeeId,
    required this.title,
    required this.category,
    required this.filePath,
    required this.addedOn,
    this.empName,
  });

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'employee_id': employeeId,
    'title': title,
    'category': category,
    'file_path': filePath,
    'added_on': addedOn,
    'emp_name': empName,
  };

  factory DocumentEntity.fromMap(Map<String, Object?> map) =>
      DocumentEntity(
        id: (map['id'] as num?)?.toInt(),
        employeeId: (map['employee_id'] as num?)?.toInt() ?? 0,
        title: (map['title'] ?? '').toString(),
        category: (map['category'] ?? '').toString(),
        filePath: (map['file_path'] ?? '').toString(),
        addedOn: (map['added_on'] ?? '').toString(),
        empName: map['emp_name']?.toString(),
      );

  Object? operator [](String key) => toMap()[key];

  String s(String key, [String def = '']) =>
      toMap()[key]?.toString() ?? def;

  int? i(String key) {
    final val = toMap()[key];
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val?.toString() ?? '');
  }

  double d(String key, [double def = 0.0]) {
    final val = toMap()[key];
    if (val is double) return val;
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '') ?? def;
  }
}
