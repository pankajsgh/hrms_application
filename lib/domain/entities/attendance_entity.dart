class AttendanceEntity {
  final int? id;
  final int employeeId;
  final String date;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final String note;

  const AttendanceEntity({
    this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.note = '',
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'employee_id': employeeId,
        'date': date,
        'status': status,
        'check_in': checkIn,
        'check_out': checkOut,
        'note': note,
      };

  factory AttendanceEntity.fromMap(Map<String, Object?> map) => AttendanceEntity(
        id: map['id'] as int?,
        employeeId: (map['employee_id'] as num?)?.toInt() ?? 0,
        date: (map['date'] ?? '').toString(),
        status: (map['status'] ?? '').toString(),
        checkIn: map['check_in']?.toString(),
        checkOut: map['check_out']?.toString(),
        note: (map['note'] ?? '').toString(),
      );
}
