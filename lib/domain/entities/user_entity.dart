class UserEntity {
  final int? id;
  final String username;
  final String password;
  final String role;
  final int? employeeId;
  final int mustChange;
  final int active;
  final String? empName;

  const UserEntity({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    this.employeeId,
    this.mustChange = 1,
    this.active = 1,
    this.empName,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'username': username,
        'password': password,
        'role': role,
        'employee_id': employeeId,
        'must_change': mustChange,
        'active': active,
      };

  factory UserEntity.fromMap(Map<String, Object?> map) => UserEntity(
        id: map['id'] as int?,
        username: (map['username'] ?? '').toString(),
        password: (map['password'] ?? '').toString(),
        role: (map['role'] ?? 'employee').toString(),
        employeeId: map['employee_id'] as int?,
        mustChange: (map['must_change'] as num?)?.toInt() ?? 1,
        active: (map['active'] as num?)?.toInt() ?? 1,
        empName: map['emp_name']?.toString(),
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
