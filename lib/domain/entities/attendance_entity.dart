class AttendanceEntity {
  final int? id;
  final int employeeId;
  final String date;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final String note;

  // Joined employee information
  final String? empName;
  final String? code;
  final String? department;

  const AttendanceEntity({
    this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.note = '',
    this.empName,
    this.code,
    this.department,
  });

  // Only actual attendance table columns.
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'employee_id': employeeId,
    'date': date,
    'status': status,
    'check_in': checkIn,
    'check_out': checkOut,
    'note': note,
  };

  factory AttendanceEntity.fromMap(Map<String, Object?> map) {
    return AttendanceEntity(
      id: (map['id'] as num?)?.toInt(),
      employeeId:
      ((map['employee_id'] ?? map['emp_id']) as num?)?.toInt() ?? 0,
      date: (map['date'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      checkIn: map['check_in']?.toString(),
      checkOut: map['check_out']?.toString(),
      note: (map['note'] ?? '').toString(),
      empName: map['emp_name']?.toString() ?? map['name']?.toString(),
      code: map['code']?.toString(),
      department: map['department']?.toString(),
    );
  }

  Object? operator [](String key) {
    switch (key) {
      case 'id':
        return id;

      case 'employee_id':
      case 'emp_id':
        return employeeId;

      case 'date':
        return date;

      case 'status':
        return status;

      case 'check_in':
        return checkIn;

      case 'check_out':
        return checkOut;

      case 'note':
        return note;

      case 'name':
      case 'emp_name':
        return empName;

      case 'code':
        return code;

      case 'department':
        return department;

      default:
        return null;
    }
  }

  String s(String key, [String def = '']) {
    return this[key]?.toString() ?? def;
  }

  int? i(String key) {
    final value = this[key];

    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '');
  }

  double d(String key, [double def = 0.0]) {
    final value = this[key];

    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? def;
  }
}