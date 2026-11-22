
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ============================================================
// PASSWORD HELPERS
// ============================================================

String hashPassword(String password, [String? salt]) {
  salt ??= base64Url.encode(
    List<int>.generate(
      12,
          (_) => Random.secure().nextInt(256),
    ),
  );

  final hash = sha256
      .convert(utf8.encode('$salt:$password'))
      .toString();

  return '$salt:$hash';
}

bool checkPassword(String password, String stored) {
  final index = stored.indexOf(':');

  if (index < 0) return false;

  final salt = stored.substring(0, index);

  return hashPassword(password, salt) == stored;
}

// ============================================================
// DATABASE
// ============================================================

class Db {
  Db._();

  static late Database db;

  static const String databaseName = 'hrms.db';

  // ==========================================================
  // INITIALIZE DATABASE
  // ==========================================================

  static Future<void> init() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final directory = await getApplicationSupportDirectory();

    await directory.create(recursive: true);

    db = await openDatabase(
      p.join(directory.path, databaseName),
      version: 4,
      onCreate: (database, _) async {
        await _createTables(database);
        await _seedDefaults(database);
      },
    );
  }

  // ==========================================================
  // CREATE ALL TABLES
  // ==========================================================

  static Future<void> _createTables(Database database) async {
    final batch = database.batch();

    // --------------------------------------------------------
    // 1. EMPLOYEES
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        department TEXT,
        designation TEXT,
        branch TEXT,
        manager_id INTEGER,
        join_date TEXT,
        status TEXT DEFAULT 'Active',
        address TEXT,
        bank_account TEXT,
        basic REAL DEFAULT 0,
        hra REAL DEFAULT 0,
        allowances REAL DEFAULT 0,
        pf_percent REAL DEFAULT 0,
        other_deduction REAL DEFAULT 0
      )
    ''');

    // --------------------------------------------------------
    // 2. USERS
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        employee_id INTEGER,
        must_change INTEGER DEFAULT 0,
        active INTEGER DEFAULT 1
      )
    ''');

    // --------------------------------------------------------
    // 3. ATTENDANCE
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT,
        check_in TEXT,
        check_out TEXT,
        note TEXT,
        UNIQUE(employee_id, date)
      )
    ''');

    // --------------------------------------------------------
    // 4. LEAVE TYPES
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE leave_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        days_per_year REAL DEFAULT 0,
        paid INTEGER DEFAULT 1
      )
    ''');

    // --------------------------------------------------------
    // 5. LEAVES
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE leaves (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        type_id INTEGER,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        days REAL DEFAULT 0,
        reason TEXT,
        status TEXT DEFAULT 'Pending',
        decided_by INTEGER,
        decided_on TEXT,
        applied_on TEXT
      )
    ''');

    // --------------------------------------------------------
    // 6. HOLIDAYS
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE holidays (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL
      )
    ''');

    // --------------------------------------------------------
    // 7. PAYROLL
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE payroll (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        working_days REAL DEFAULT 0,
        paid_days REAL DEFAULT 0,
        basic REAL DEFAULT 0,
        hra REAL DEFAULT 0,
        allowances REAL DEFAULT 0,
        gross REAL DEFAULT 0,
        pf REAL DEFAULT 0,
        other_deduction REAL DEFAULT 0,
        net REAL DEFAULT 0,
        generated_on TEXT,
        UNIQUE(employee_id, month)
      )
    ''');

    // --------------------------------------------------------
    // 8. JOBS
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        department TEXT,
        openings INTEGER DEFAULT 1,
        status TEXT DEFAULT 'Open',
        description TEXT,
        branch TEXT,
        location TEXT,
        employment_type TEXT,
        experience TEXT,
        salary_min REAL,
        salary_max REAL,
        skills TEXT,
        closing_date TEXT,
        approval TEXT DEFAULT 'Approved',
        created_by INTEGER,
        approved_by INTEGER,
        approved_on TEXT,
        reject_reason TEXT,
        created_on TEXT
      )
    ''');

    // --------------------------------------------------------
    // 9. CANDIDATES
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE candidates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        stage TEXT,
        notes TEXT,
        applied_on TEXT,
        source TEXT,
        experience_years REAL,
        current_company TEXT,
        expected_salary REAL,
        rating REAL DEFAULT 0,
        resume_path TEXT,
        stage_changed_on TEXT,
        converted_employee_id INTEGER
      )
    ''');

    // --------------------------------------------------------
    // 10. INTERVIEWS
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE interviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        candidate_id INTEGER NOT NULL,
        round TEXT,
        scheduled_at TEXT,
        mode TEXT,
        interviewer_id INTEGER,
        location TEXT,
        notes TEXT,
        result TEXT DEFAULT 'Scheduled',
        feedback TEXT
      )
    ''');

    // --------------------------------------------------------
    // 11. SPECIAL DAYS
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE special_days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        kind TEXT,
        title TEXT,
        date TEXT,
        yearly INTEGER DEFAULT 0,
        created_by INTEGER,
        created_on TEXT
      )
    ''');

    // --------------------------------------------------------
    // 12. GOALS
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        progress INTEGER DEFAULT 0,
        status TEXT DEFAULT 'Pending'
      )
    ''');

    // --------------------------------------------------------
    // 13. REVIEWS
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        reviewer_id INTEGER,
        period TEXT,
        rating REAL DEFAULT 0,
        strengths TEXT,
        improvements TEXT,
        comments TEXT,
        created_on TEXT
      )
    ''');

    // --------------------------------------------------------
    // 14. DOCUMENTS
    // --------------------------------------------------------

    batch.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        category TEXT,
        file_path TEXT NOT NULL,
        added_on TEXT
      )
    ''');

    await batch.commit(noResult: true);

    // Create indexes for commonly queried columns.
    await _createIndexes(database);
  }

  // ==========================================================
  // INDEXES
  // ==========================================================

  static Future<void> _createIndexes(Database database) async {
    final batch = database.batch();

    batch.execute('''
      CREATE INDEX idx_attendance_employee_date
      ON attendance(employee_id, date)
    ''');

    batch.execute('''
      CREATE INDEX idx_leaves_employee
      ON leaves(employee_id)
    ''');

    batch.execute('''
      CREATE INDEX idx_payroll_employee_month
      ON payroll(employee_id, month)
    ''');

    batch.execute('''
      CREATE INDEX idx_candidates_job
      ON candidates(job_id)
    ''');

    batch.execute('''
      CREATE INDEX idx_interviews_candidate
      ON interviews(candidate_id)
    ''');

    batch.execute('''
      CREATE INDEX idx_goals_employee
      ON goals(employee_id)
    ''');

    batch.execute('''
      CREATE INDEX idx_documents_employee
      ON documents(employee_id)
    ''');

    batch.execute('''
      CREATE INDEX idx_reviews_employee
      ON reviews(employee_id)
    ''');

    await batch.commit(noResult: true);
  }

  // ==========================================================
  // DEFAULT DATA
  // ==========================================================

  static Future<void> _seedDefaults(Database database) async {
    await database.transaction((txn) async {
      // Default leave types.

      final leaveTypes = [
        ['Casual', 12, 1],
        ['Sick', 10, 1],
        ['Earned', 15, 1],
        ['Unpaid', 0, 0],
      ];

      for (final leave in leaveTypes) {
        await txn.insert('leave_types', {
          'name': leave[0],
          'days_per_year': leave[1],
          'paid': leave[2],
        });
      }

      // Default administrator employee.

      final employeeId = await txn.insert('employees', {
        'code': 'EMP001',
        'name': 'Administrator',
        'department': 'Administration',
        'designation': 'System Administrator',
        'status': 'Active',
      });

      // Default administrator login.

      await txn.insert('users', {
        'username': 'admin',
        'password': hashPassword('admin123'),
        'role': 'admin',
        'employee_id': employeeId,
        'must_change': 1,
        'active': 1,
      });
    });
  }

  // ==========================================================
  // CLEAR ALL DATA
  // ==========================================================

  static Future<void> clearAllData() async {
    await db.transaction((txn) async {
      const tables = [
        'interviews',
        'candidates',
        'jobs',
        'documents',
        'reviews',
        'goals',
        'special_days',
        'payroll',
        'leaves',
        'attendance',
        'holidays',
        'leave_types',
        'users',
        'employees',
      ];

      for (final table in tables) {
        await txn.delete(table);
      }

      await txn.delete('sqlite_sequence');
    });
  }

  // ==========================================================
  // CLOSE DATABASE
  // ==========================================================

  static Future<void> close() async {
    if (db.isOpen) {
      await db.close();
    }
  }

  static Future<void> resetDatabase() async {
    if (db.isOpen) {
      await db.close();
    }

    final directory = await getApplicationSupportDirectory();
    final path = p.join(directory.path, databaseName);

    await deleteDatabase(path);

    await init();

    print('Database deleted and recreated successfully');
  }
}
