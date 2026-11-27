

class EmployeeEntity {
  final int? id;
  final String code;
  final String name;
  final String? email;
  final String? phone;
  final String? department;
  final String? designation;
  final String? branch;
  final int? managerId;
  final String? joinDate;
  final String status;
  final String? address;
  final String? bankAccount;
  final double basic;
  final double hra;
  final double allowances;
  final double pfPercent;
  final double otherDeduction;

  const EmployeeEntity({
    this.id,
    required this.code,
    required this.name,
    this.email,
    this.phone,
    this.department,
    this.designation,
    this.branch,
    this.managerId,
    this.joinDate,
    this.status = 'Active',
    this.address,
    this.bankAccount,
    this.basic = 0,
    this.hra = 0,
    this.allowances = 0,
    this.pfPercent = 12,
    this.otherDeduction = 0,
  });

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'code': code,
    'name': name,
    'email': email,
    'phone': phone,
    'department': department,
    'designation': designation,
    'branch': branch,
    'manager_id': managerId,
    'join_date': joinDate,
    'status': status,
    'address': address,
    'bank_account': bankAccount,
    'basic': basic,
    'hra': hra,
    'allowances': allowances,
    'pf_percent': pfPercent,
    'other_deduction': otherDeduction,
  };

  factory EmployeeEntity.fromMap(Map<String, Object?> map) {
    return EmployeeEntity(
      id: (map['id'] as num?)?.toInt(),
      code: (map['code'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      department: map['department']?.toString(),
      designation: map['designation']?.toString(),
      branch: map['branch']?.toString(),
      managerId: (map['manager_id'] as num?)?.toInt(),
      joinDate: map['join_date']?.toString(),
      status: (map['status'] ?? 'Active').toString(),
      address: map['address']?.toString(),
      bankAccount: map['bank_account']?.toString(),
      basic: (map['basic'] as num?)?.toDouble() ?? 0,
      hra: (map['hra'] as num?)?.toDouble() ?? 0,
      allowances: (map['allowances'] as num?)?.toDouble() ?? 0,
      pfPercent: (map['pf_percent'] as num?)?.toDouble() ?? 12,
      otherDeduction:
      (map['other_deduction'] as num?)?.toDouble() ?? 0,
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
