

import 'package:hrms/core/common.dart';

MonthCalc calc(
    Rec employee,
    int year,
    int month,
    List<Rec> records,
    Set<String> holidayDates, {
      DateTime? upTo,
    }) {
  final result = MonthCalc();

  final byDate = {
    for (final record in records) record.s('date'): record,
  };

  final joinDate = employee.s('join_date').isEmpty
      ? null
      : DateTime.tryParse(employee.s('join_date'));

  final lastDay = DateTime(year, month + 1, 0).day;

  for (var day = 1; day <= lastDay; day++) {
    final date = DateTime(year, month, day);

    if (upTo != null &&
        date.isAfter(DateTime(upTo.year, upTo.month, upTo.day))) {
      break;
    }

    final key = ymd(date);
    final record = byDate[key];

    final isWeekday = date.weekday <= DateTime.friday;
    final isHoliday = holidayDates.contains(key);

    final isBeforeJoining = joinDate != null &&
        date.isBefore(
          DateTime(joinDate.year, joinDate.month, joinDate.day),
        );

    if (isBeforeJoining) continue;

    if (record != null) {
      final duration = workedBetween(
        record['check_in'],
        record['check_out'],
      );

      if (duration != null) {
        result.hours += duration;
      }
    }

    if (isWeekday && !isHoliday) {
      result.working++;
    }

    if (record == null) {
      if (!isWeekday) continue;

      if (isHoliday) {
        result.holidays++;
        result.paid++;
      } else {
        result.absent++;
      }

      continue;
    }

    switch (record.s('status')) {
      case 'Present':
        result.present++;
        result.paid++;

        if (!isWeekday && !isHoliday) {
          result.working++;
        }
        break;

      case 'Half Day':
        result.half++;
        result.paid += 0.5;

        if (!isWeekday && !isHoliday) {
          result.working += 0.5;
        }
        break;

      case 'Leave':
        result.leave++;
        result.paid++;
        break;

      case 'Unpaid Leave':
        result.unpaid++;
        break;

      default:
        result.absent++;
    }
  }

  return result;
}

class MonthCalc {
  double working = 0;
  double paid = 0;
  double present = 0;
  double half = 0;
  double leave = 0;
  double unpaid = 0;
  double absent = 0;
  double holidays = 0;

  Duration hours = Duration.zero;

  double get totalHours => hours.inMinutes / 60.0;

  double get daysAttended => present + half;

  double get daysWorked => present + (half * 0.5);

  double get avgDailyHours =>
      daysAttended > 0 ? totalHours / daysAttended : 0;

  double get attendanceRate =>
      working > 0 ? (daysWorked / working) * 100 : 0;
}
