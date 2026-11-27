import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';

class FillDemoData {


  static Future<void> seedDemoData() async {
    final now = DateTime.now();

    String date(int daysAgo) {
      return ymd(now.subtract(Duration(days: daysAgo)));
    }

    String moneyMonth() {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }

    // Prevent accidental duplicate demo data.
    final existing = await Db.db.rawQuery(
      'SELECT COUNT(*) AS total FROM employees',
    );

    if ((existing.first['total'] as num) > 0) {
      throw Exception(
        'Database already contains employees. Clear the data first.',
      );
    }


    await Db.db.transaction((txn) async {
      // ---------------------------------------------------------
      // 1. EMPLOYEES - 10 RECORDS
      // ---------------------------------------------------------

      final employeeIds = <int>[];

      final departments = [
        'IT',
        'HR',
        'Sales',
        'Finance',
        'Marketing',
        'Operations',
        'Support',
        'Management',
        'IT',
        'Sales',
      ];

      final designations = [
        'Flutter Developer',
        'HR Manager',
        'Sales Executive',
        'Accountant',
        'Marketing Executive',
        'Operations Manager',
        'Support Engineer',
        'Team Lead',
        'Backend Developer',
        'Sales Manager',
      ];

      for (int i = 0; i < 10; i++) {
        final id = await txn.insert(
            'employees',
            {
          'code': 'EMP${(i + 1).toString().padLeft(3, '0')}',
          'name': [
            'Rahul Sharma',
            'Amit Kumar',
            'Priya Singh',
            'Neha Verma',
            'Rohit Gupta',
            'Anjali Sharma',
            'Vikas Yadav',
            'Pooja Mishra',
            'Arjun Patel',
            'Sneha Jain',
          ][i],
          'email': 'employee${i + 1}@demo.com',
          'phone': '98765432${(10 + i)}',
          'department': departments[i],
          'designation': designations[i],
          'branch': i.isEven ? 'Delhi' : 'Noida',
          'manager_id': null,
          'join_date': date(100 + i * 10),
          'status': i == 9 ? 'Inactive' : 'Active',
          'address': 'Demo Address ${i + 1}, India',
          'bank_account': '123456789${i}',
          'basic': 25000 + (i * 2000),
          'hra': 5000 + (i * 500),
          'allowances': 3000 + (i * 300),
          'pf_percent': 12,
          'other_deduction': 500,
        });

        employeeIds.add(id);
      }

      // ---------------------------------------------------------
      // 2. USERS - 10 RECORDS
      // ---------------------------------------------------------

      for (int i = 0; i < 10; i++) {
        await txn.insert('users', {
          'username': i == 0 ? 'admin' : 'employee${i + 1}',
          'password': hashPassword(
            i == 0 ? 'admin123' : '123456',
          ),
          'role': i == 0 ? 'admin' : 'employee',
          'employee_id': employeeIds[i],
          'must_change': 0,
          'active': 1,
        });
      }

      // ---------------------------------------------------------
      // 3. LEAVE TYPES - 10 RECORDS
      // ---------------------------------------------------------

      final leaveTypeIds = <int>[];

      final leaveTypes = [
        ['Casual Leave', 12, 1],
        ['Sick Leave', 10, 1],
        ['Earned Leave', 15, 1],
        ['Unpaid Leave', 0, 0],
        ['Maternity Leave', 90, 1],
        // ['Paternity Leave', 15, 1],
        // ['Marriage Leave', 5, 1],
        // ['Bereavement Leave', 5, 1],
        // ['Compensatory Leave', 5, 1],
        // ['Study Leave', 10, 1],
      ];

      for (final t in leaveTypes) {
        final id = await txn.insert('leave_types', {
          'name': t[0],
          'days_per_year': t[1],
          'paid': t[2],
        });

        leaveTypeIds.add(id);
      }

      // ---------------------------------------------------------
      // 4. ATTENDANCE - LAST 26 DAYS FOR ALL 10 EMPLOYEES
      // Total: 260 records
      // ---------------------------------------------------------

      for (int employee = 0; employee < 10; employee++) {
        for (int day = 0; day < 26; day++) {
          final status = (day + employee) % 12 == 0
              ? 'Absent'
              : (day + employee) % 9 == 0
              ? 'Half Day'
              : 'Present';

          await txn.insert('attendance', {
            'employee_id': employeeIds[employee],
            'date': date(day),
            'status': status,
            'check_in': status == 'Absent'
                ? null
                : '09:${(day % 5) * 10}'.padRight(5, '0'),
            'check_out': status == 'Absent'
                ? null
                : status == 'Half Day'
                ? '13:00'
                : '18:00',
            'note': 'Demo attendance',
          });
        }
      }

      // ---------------------------------------------------------
      // 5. HOLIDAYS - 10 RECORDS
      // ---------------------------------------------------------

      final holidayNames = [
        'New Year',
        'Republic Day',
        'Holi',
        'Good Friday',
        'Independence Day',
        'Gandhi Jayanti',
        'Dussehra',
        'Diwali',
        'Christmas',
        'Company Foundation Day',
      ];

      for (int i = 0; i < 10; i++) {
        await txn.insert('holidays', {
          'date': date(-30 - (i * 10)),
          'name': holidayNames[i],
        });
      }

      // ---------------------------------------------------------
      // 6. PAYROLL - 10 RECORDS
      // ---------------------------------------------------------

      for (int i = 0; i < 10; i++) {
        final basic = 25000.0 + (i * 2000);
        final hra = 5000.0 + (i * 500);
        final allowances = 3000.0 + (i * 300);
        final gross = basic + hra + allowances;
        final pf = basic * 0.12;
        final deduction = 500.0;
        final net = gross - pf - deduction;

        await txn.insert('payroll', {
          'employee_id': employeeIds[i],
          'month': moneyMonth(),
          'working_days': 26,
          'paid_days': 26,
          'basic': basic,
          'hra': hra,
          'allowances': allowances,
          'gross': gross,
          'pf': pf,
          'other_deduction': deduction,
          'net': net,
          'generated_on': date(0),
        });
      }

      // ---------------------------------------------------------
      // 7. JOBS - 10 RECORDS
      // ---------------------------------------------------------

      final jobIds = <int>[];

      final jobTitles = [
        'Flutter Developer',
        'Backend Developer',
        'HR Executive',
        'UI/UX Designer',
        'Sales Manager',
        'Accountant',
        'Digital Marketing Executive',
        'QA Engineer',
        'Project Manager',
        'Business Analyst',
      ];

      for (int i = 0; i < 10; i++) {
        final id = await txn.insert('jobs', {
          'title': jobTitles[i],
          'department': departments[i],
          'branch': i.isEven ? 'Delhi' : 'Noida',
          'openings': 2,
          'status': 'Open',
          'description': 'Demo job description for ${jobTitles[i]}',
          'location': i.isEven ? 'Delhi' : 'Noida',
          'employment_type': 'Full-time',
          'experience': '2-5 Years',
          'salary_min': 300000 + (i * 20000),
          'salary_max': 600000 + (i * 30000),
          'skills': 'Communication, Teamwork, Technical Skills',
          'closing_date': date(-60),
          'approval': 'Approved',
          'created_by': employeeIds[0],
          'approved_by': employeeIds[0],
          'approved_on': date(5),
          'created_on': date(10),
        });

        jobIds.add(id);
      }

      // ---------------------------------------------------------
      // 8. CANDIDATES - 10 RECORDS
      // ---------------------------------------------------------

      final candidateIds = <int>[];

      final candidateStages = [
        'Applied',
        'Screening',
        'Shortlisted',
        'Interview',
        'Hired',
        'Rejected',
        'Applied',
        'Screening',
        'Interview',
        'Shortlisted',
      ];

      for (int i = 0; i < 10; i++) {
        final id = await txn.insert('candidates', {
          'job_id': jobIds[i],
          'name': 'Candidate ${i + 1}',
          'email': 'candidate${i + 1}@demo.com',
          'phone': '91234567${10 + i}',
          'stage': candidateStages[i],
          'notes': 'Demo candidate profile',
          'applied_on': date(i + 1),
          'source': 'LinkedIn',
          'experience_years': 1 + (i % 6),
          'current_company': 'Company ${i + 1}',
          'expected_salary': 400000 + (i * 25000),
          'rating': 3 + (i % 3),
          'resume_path': '',
          'stage_changed_on': date(i),
          'converted_employee_id': null,
        });

        candidateIds.add(id);
      }

      // ---------------------------------------------------------
// 9. INTERVIEWS - ONLY INTERVIEW-STAGE CANDIDATES
// ---------------------------------------------------------

      for (int i = 0; i < 10; i++) {
        if (candidateStages[i] != 'Interview') continue;

        final interviewDate = now.add(Duration(days: i + 1));

        await txn.insert('interviews', {
          'candidate_id': candidateIds[i],
          'round': i.isEven ? 'Technical' : 'HR',
          'scheduled_at': DateTime(
            interviewDate.year,
            interviewDate.month,
            interviewDate.day,
            10 + (i % 6),
          ).toIso8601String(),
          'mode': 'Online',
          'interviewer_id': employeeIds[0],
          'location': 'Delhi Office',
          'notes': 'Demo interview ${i + 1}',
          'result': 'Scheduled',
          'feedback': '',
        });
      }
      // ---------------------------------------------------------
      // 10. GOALS - 10 RECORDS
      // ---------------------------------------------------------

      for (int i = 0; i < 10; i++) {
        await txn.insert('goals', {
          'employee_id': employeeIds[i],
          'title': 'Complete monthly target ${i + 1}',
          'description': 'Improve productivity and complete assigned work.',
          'due_date': date(-30),
          'progress': (i * 10) % 100,
          'status': i.isEven ? 'In Progress' : 'Completed',
        });
      }

      // ---------------------------------------------------------
      // 11. PERFORMANCE REVIEWS - 10 RECORDS
      // ---------------------------------------------------------

      for (int i = 0; i < 10; i++) {
        await txn.insert('reviews', {
          'employee_id': employeeIds[i],
          'reviewer_id': employeeIds[0],
          'period': moneyMonth(),
          'rating': 3 + (i % 3),
          'strengths': 'Good teamwork and communication.',
          'improvements': 'Improve time management.',
          'comments': 'Demo performance review.',
          'created_on': date(2),
        });
      }

      // ---------------------------------------------------------
      // 12. DOCUMENTS - 10 RECORDS
      // ---------------------------------------------------------

      for (int i = 0; i < 10; i++) {
        await txn.insert('documents', {
          'employee_id': employeeIds[i],
          'title': 'Employee Document ${i + 1}',
          'category': 'General',
          'file_path': 'demo/document_${i + 1}.pdf',
          'added_on': date(i),
        });
      }

      // ---------------------------------------------------------
      // 13. SPECIAL DAYS - 10 RECORDS
      // ---------------------------------------------------------

      for (int i = 0; i < 10; i++) {
        await txn.insert('special_days', {
          'employee_id': employeeIds[i],
          'kind': i.isEven ? 'Birthday' : 'Anniversary',
          'title': i.isEven ? 'Birthday' : 'Work Anniversary',
          'date': date(-20 - i),
          'yearly': 1,
          'created_by': employeeIds[0],
          'created_on': date(0),
        });
      }
    });
  }

}
