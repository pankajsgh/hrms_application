import 'package:intl/intl.dart';

typedef Rec = Map<String, Object?>;

extension RecX on Map<String, Object?> {
  String s(String k) => (this[k] ?? '').toString();
  double d(String k) => (this[k] as num?)?.toDouble() ?? 0;
  int? i(String k) => (this[k] as num?)?.toInt();
}

const kStatuses = ['Present', 'Half Day', 'Leave', 'Unpaid Leave', 'Absent'];
const kStages = [
  'Applied',
  'Screening',
  'Shortlisted',
  'Interview',
  'Offered',
  'Hired',
  'Rejected'
];
const kRoles = {
  'admin': 'Admin',
  'hr': 'HR',
  'manager': 'Manager',
  'recruiter': 'Recruiter',
  'employee': 'Employee',
};

final _ymd = DateFormat('yyyy-MM-dd');
String ymd(DateTime d) => _ymd.format(d);

DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

String fmtDate(Object? s) {
  if (s == null || s.toString().isEmpty) return '';
  final d = DateTime.tryParse(s.toString());
  return d == null ? s.toString() : DateFormat('d MMM yyyy').format(d);
}

String fmtTime(Object? s) {
  if (s == null || s.toString().isEmpty) return '';
  final str = s.toString().trim();
  if (str.length <= 8 && str.contains(':')) {
    final parts = str.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final dt = DateTime(2022, 1, 1, hour, minute);
      return DateFormat('hh:mm a').format(dt);
    }
  }
  final d = DateTime.tryParse(str);
  if (d != null) {
    return DateFormat('hh:mm a').format(d);
  }
  return str;
}

String money(num v) => '₹ ${NumberFormat('#,##0.00').format(v)}';

String monthKey(int y, int m) => '$y-${m.toString().padLeft(2, '0')}';

String monthLabel(String key) =>
    DateFormat('MMMM yyyy').format(DateTime.parse('$key-01'));

Duration? workedBetween(Object? a, Object? b) {
  if (a == null || b == null) return null;
  final aStr = a.toString().trim();
  final bStr = b.toString().trim();

  DateTime? i = DateTime.tryParse(aStr);
  DateTime? o = DateTime.tryParse(bStr);

  if (i == null && aStr.contains(':')) {
    final p = aStr.split(':');
    if (p.length >= 2) {
      i = DateTime(2022, 1, 1, int.tryParse(p[0]) ?? 0, int.tryParse(p[1]) ?? 0);
    }
  }
  if (o == null && bStr.contains(':')) {
    final p = bStr.split(':');
    if (p.length >= 2) {
      o = DateTime(2022, 1, 1, int.tryParse(p[0]) ?? 0, int.tryParse(p[1]) ?? 0);
    }
  }

  if (i == null || o == null || !o.isAfter(i)) return null;
  return o.difference(i);
}

String fmtDuration(Duration d) =>
    '${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m';

double r2(double v) => (v * 100).roundToDouble() / 100;

/// 3.0 -> "3", 2.5 -> "2.5"
String nf(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();




/// ['a','b'] -> {'a':'a','b':'b'} for dropdown options.
Map<String, String> opts(List<String> l) => {for (final x in l) x: x};
