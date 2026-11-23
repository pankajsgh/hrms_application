
class PayrollEntity {
  final int? id;
  final int employeeId;
  final String month;
  final double workingDays;
  final double paidDays;
  final double basic;
  final double hra;
  final double allowances;
  final double gross;
  final double pf;
  final double otherDeduction;
  final double net;
  final String generatedOn;
  final String? name;
  final String? code;
  final String? department;
  final String? designation;
  final String? bankAccount;

  const PayrollEntity({
    this.id,
    required this.employeeId,
    required this.month,
    required this.workingDays,
    required this.paidDays,
    required this.basic,
    required this.hra,
    required this.allowances,
    required this.gross,
    required this.pf,
    required this.otherDeduction,
    required this.net,
    required this.generatedOn,
    this.name,
    this.code,
    this.department,
    this.designation,
    this.bankAccount,
  });

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'employee_id': employeeId,
    'month': month,
    'working_days': workingDays,
    'paid_days': paidDays,
    'basic': basic,
    'hra': hra,
    'allowances': allowances,
    'gross': gross,
    'pf': pf,
    'other_deduction': otherDeduction,
    'net': net,
    'generated_on': generatedOn,

    // Employee details
    'name': name,
    'code': code,
    'department': department,
    'designation': designation,
    'bank_account': bankAccount,
  };

  factory PayrollEntity.fromMap(Map<String, Object?> map) => PayrollEntity(
    id: (map['id'] as num?)?.toInt(),
    employeeId: (map['employee_id'] as num?)?.toInt() ?? 0,
    month: (map['month'] ?? '').toString(),
    workingDays: (map['working_days'] as num?)?.toDouble() ?? 0,
    paidDays: (map['paid_days'] as num?)?.toDouble() ?? 0,
    basic: (map['basic'] as num?)?.toDouble() ?? 0,
    hra: (map['hra'] as num?)?.toDouble() ?? 0,
    allowances: (map['allowances'] as num?)?.toDouble() ?? 0,
    gross: (map['gross'] as num?)?.toDouble() ?? 0,
    pf: (map['pf'] as num?)?.toDouble() ?? 0,
    otherDeduction:
    (map['other_deduction'] as num?)?.toDouble() ?? 0,
    net: (map['net'] as num?)?.toDouble() ?? 0,
    generatedOn: (map['generated_on'] ?? '').toString(),
    name: map['name']?.toString(),
    code: map['code']?.toString(),
    department: map['department']?.toString(),
    designation: map['designation']?.toString(),
    bankAccount: map['bank_account']?.toString(),
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
