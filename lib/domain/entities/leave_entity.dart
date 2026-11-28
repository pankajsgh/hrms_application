import 'dart:convert';

class LeaveEntity {
  final int? id;
  final int employeeId;
  final int typeId;
  final String startDate;
  final String endDate;
  final double days;
  final String reason;
  final String status;
  final String appliedOn;
  final int? decidedBy;
  final String? decidedOn;
  final String? empName;
  final String? empCode;
  final String? department;
  final String? typeName;
  final int? paid;

  const LeaveEntity({
    this.id,
    required this.employeeId,
    required this.typeId,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.status,
    required this.appliedOn,
    this.decidedBy,
    this.decidedOn,
    this.empName,
    this.empCode,
    this.department,
    this.typeName,
    this.paid,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'employee_id': employeeId,
        'type_id': typeId,
        'start_date': startDate,
        'end_date': endDate,
        'days': days,
        'reason': reason,
        'status': status,
        'applied_on': appliedOn,
        'decided_by': decidedBy,
        'decided_on': decidedOn,
        if (empName != null) 'emp_name': empName,
        if (empCode != null) 'emp_code': empCode,
        if (department != null) 'department': department,
        if (typeName != null) 'type_name': typeName,
        if (paid != null) 'paid': paid,
      };

  factory LeaveEntity.fromMap(Map<String, Object?> map) => LeaveEntity(
        id: map['id'] as int?,
        employeeId: (map['employee_id'] as num?)?.toInt() ?? 0,
        typeId: (map['type_id'] as num?)?.toInt() ?? 0,
        startDate: (map['start_date'] ?? '').toString(),
        endDate: (map['end_date'] ?? '').toString(),
        days: (map['days'] as num?)?.toDouble() ?? 0,
        reason: (map['reason'] ?? '').toString(),
        status: (map['status'] ?? 'Pending').toString(),
        appliedOn: (map['applied_on'] ?? '').toString(),
        decidedBy: map['decided_by'] as int?,
        decidedOn: map['decided_on']?.toString(),
        empName: map['emp_name']?.toString(),
        empCode: map['emp_code']?.toString(),
        department: map['department']?.toString(),
        typeName: map['type_name']?.toString(),
        paid: map['paid'] as int?,
      );

  Object? operator [](String key) => toMap()[key];
  String s(String key, [String def = '']) => toMap()[key]?.toString() ?? def;
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

class LeaveTypeEntity {
  final int? id;
  final String name;
  final double daysPerYear;
  final int paid;

  const LeaveTypeEntity({
    this.id,
    required this.name,
    required this.daysPerYear,
    required this.paid,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'days_per_year': daysPerYear,
        'paid': paid,
      };

  factory LeaveTypeEntity.fromMap(Map<String, Object?> map) => LeaveTypeEntity(
        id: map['id'] as int?,
        name: (map['name'] ?? '').toString(),
        daysPerYear: (map['days_per_year'] as num?)?.toDouble() ?? 0,
        paid: (map['paid'] as num?)?.toInt() ?? 0,
      );

  Object? operator [](String key) => toMap()[key];
  String s(String key, [String def = '']) => toMap()[key]?.toString() ?? def;
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

class LeaveBalanceEntity {
  final int id;
  final String name;
  final double daysPerYear;
  final int paid;
  final double used;
  final double pending;
  final List<LeaveApplicationEntity> applications;

  const LeaveBalanceEntity({
    required this.id,
    required this.name,
    required this.daysPerYear,
    required this.paid,
    required this.used,
    required this.pending,
    this.applications = const [],
  });

  double get available => daysPerYear - used - pending;

  factory LeaveBalanceEntity.fromMap(Map<String, Object?> map) {
    final rawApplications = map['applications'];

    final List<dynamic> applicationList = rawApplications is String
        ? (jsonDecode(rawApplications) as List<dynamic>)
        : rawApplications is List
        ? rawApplications
        : [];

    return LeaveBalanceEntity(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: (map['name'] ?? '').toString(),
      daysPerYear: (map['days_per_year'] as num?)?.toDouble() ?? 0,
      paid: (map['paid'] as num?)?.toInt() ?? 0,
      used: (map['used'] as num?)?.toDouble() ?? 0,
      pending: (map['pending'] as num?)?.toDouble() ?? 0,
      applications: applicationList
          .map((e) => LeaveApplicationEntity.fromMap(
        Map<String, Object?>.from(e as Map),
      ))
          .toList(),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'days_per_year': daysPerYear,
    'paid': paid,
    'used': used,
    'pending': pending,
    'applications': applications.map((e) => e.toMap()).toList(),
  };

  Object? operator [](String key) => toMap()[key];

  String s(String key, [String def = '']) =>
      toMap()[key]?.toString() ?? def;

  int? i(String key) {
    final val = toMap()[key];
    if (val is num) return val.toInt();
    return int.tryParse(val?.toString() ?? '');
  }

  double d(String key, [double def = 0.0]) {
    final val = toMap()[key];
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '') ?? def;
  }
}

class LeaveApplicationEntity {
  final int id;
  final String startDate;
  final String endDate;
  final double days;
  final String status;
  final String? reason;

  const LeaveApplicationEntity({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.status,
    this.reason,
  });

  factory LeaveApplicationEntity.fromMap(Map<String, Object?> map) {
    return LeaveApplicationEntity(
      id: (map['id'] as num?)?.toInt() ?? 0,
      startDate: (map['startDate'] ?? '').toString(),
      endDate: (map['endDate'] ?? '').toString(),
      days: (map['days'] as num?)?.toDouble() ?? 0,
      status: (map['status'] ?? '').toString(),
      reason: map['reason']?.toString(),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'startDate': startDate,
    'endDate': endDate,
    'days': days,
    'status': status,
    'reason': reason,
  };
}