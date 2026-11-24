
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/data/datasources/local_datasource.dart';
import 'package:hrms/data/repositories/repository_impl.dart';
import 'package:hrms/domain/entities/recruitment_entity.dart';

class RecruitmentRepository {
  // ---------------------------------------------------------------------------
  // JOBS
  // ---------------------------------------------------------------------------

  Future<List<JobEntity>> jobs() async {
    final raw = await Repo.queryOrLocal(
      'jobs',
      {},
          () => Db.db.rawQuery(
        'SELECT j.*, '
            '(SELECT COUNT(*) FROM candidates c WHERE c.job_id = j.id) AS cands, '
            '(SELECT name FROM employees x WHERE x.id = j.created_by) AS creator_name '
            'FROM jobs j '
            "ORDER BY CASE j.approval WHEN 'Pending' THEN 0 ELSE 1 END, j.id DESC",
      ),
    );

    return raw.map((r) => JobEntity.fromMap(r)).toList();
  }

  Future<List<JobEntity>> fetchJobs() => jobs();

  Future<int> createJob(Object data) {
    final map = data is JobEntity
        ? data.toMap()
        : Map<String, Object?>.from(data as Map);

    final admin = Session.isAdmin;
    final now = ymd(DateTime.now());

    return Repo.saveData('jobs', {}, {
      ...map,
      'created_by': Session.empId,
      'created_on': now,
      'approval': admin ? 'Approved' : 'Pending',
      if (admin) 'approved_by': Session.empId,
      if (admin) 'approved_on': now,
    });
  }

  Future<void> updateJob(
      int id,
      Object data, {
        String? currentApproval,
      }) async {
    final map = data is JobEntity
        ? data.toMap()
        : Map<String, Object?>.from(data as Map);

    if (currentApproval == 'Rejected' && !Session.isAdmin) {
      map['approval'] = 'Pending';
      map['reject_reason'] = null;
    }

    await Repo.saveData('jobs', {'id': '$id'}, map);
  }

  Future<void> decideJob(
      int id,
      bool approve,
      String reason,
      ) async {
    if (!Session.isAdmin) return;

    await Db.db.update(
      'jobs',
      {
        'approval': approve ? 'Approved' : 'Rejected',
        'approved_by': Session.empId,
        'approved_on': ymd(DateTime.now()),
        'reject_reason': approve ? null : reason,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteJob(int id) async {
    final candidates = await Db.db.query(
      'candidates',
      columns: ['id'],
      where: 'job_id = ?',
      whereArgs: [id],
    );

    for (final candidate in candidates) {
      await Repo.deleteData(
        'interviews',
        {'candidate_id': '${candidate['id']}'},
      );
    }

    await Repo.deleteData('candidates', {'job_id': '$id'});
    await Repo.deleteData('jobs', {'id': '$id'});
  }

  // ---------------------------------------------------------------------------
  // CANDIDATES
  // ---------------------------------------------------------------------------

  Future<List<CandidateEntity>> candidates({
    int? jobId,
    String q = '',
  }) async {
    final queryMap = <String, String>{
      if (jobId != null) 'job_id': '$jobId',
      'q': q,
    };

    final raw = await Repo.queryOrLocal(
      'candidates',
      queryMap,
          () async {
        final where = <String>[];
        final args = <Object?>[ymd(DateTime.now())];

        if (jobId != null) {
          where.add('c.job_id = ?');
          args.add(jobId);
        }

        final search = q.trim();

        if (search.isNotEmpty) {
          where.add(
            '(c.name LIKE ? OR c.email LIKE ? OR c.phone LIKE ?)',
          );

          args.addAll([
            '%$search%',
            '%$search%',
            '%$search%',
          ]);
        }

        return Db.db.rawQuery(
          'SELECT c.*, '
              'j.title AS job_title, '
              'j.department AS job_department, '
              '(SELECT MIN(i.scheduled_at) '
              'FROM interviews i '
              'WHERE i.candidate_id = c.id '
              "AND i.result = 'Scheduled' "
              'AND i.scheduled_at >= ?) AS next_interview '
              'FROM candidates c '
              'LEFT JOIN jobs j ON j.id = c.job_id '
              '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} '
              'ORDER BY c.id DESC',
          args,
        );
      },
    );

    return raw.map((r) => CandidateEntity.fromMap(r)).toList();
  }

  Future<List<CandidateEntity>> fetchCandidates({
    int? jobId,
    String q = '',
  }) {
    return candidates(jobId: jobId, q: q);
  }

  Future<void> saveCandidate(
      Object data, {
        int? id,
      }) async {
    final map = data is CandidateEntity
        ? data.toMap()
        : Map<String, Object?>.from(data as Map);

    await Repo.saveData(
      'candidates',
      id != null ? {'id': '$id'} : {},
      map,
    );
  }

  Future<void> setStage(int id, String stage) async {
    await Db.db.update(
      'candidates',
      {
        'stage': stage,
        'stage_changed_on': ymd(DateTime.now()),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCandidate(int id) async {
    await Repo.deleteData(
      'interviews',
      {'candidate_id': '$id'},
    );

    await Repo.deleteData(
      'candidates',
      {'id': '$id'},
    );
  }

  Future<void> attachResume(int id, String source) async {
    final base = await getApplicationSupportDirectory();

    final folder = Directory(
      p.join(base.path, 'resumes', '$id'),
    );

    await folder.create(recursive: true);

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(source)}';

    final destination = p.join(folder.path, fileName);

    await File(source).copy(destination);

    await Db.db.update(
      'candidates',
      {'resume_path': destination},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markConverted(
      int candidateId,
      int employeeId,
      ) async {
    await Db.db.update(
      'candidates',
      {
        'converted_employee_id': employeeId,
        'stage': 'Hired',
        'stage_changed_on': ymd(DateTime.now()),
      },
      where: 'id = ?',
      whereArgs: [candidateId],
    );
  }

  // ---------------------------------------------------------------------------
  // INTERVIEWS
  // ---------------------------------------------------------------------------

  Future<List<InterviewEntity>> interviews() async {
    final raw = await Repo.queryOrLocal(
      'interviews',
      {'candidate_stage': 'Interview'},
          () => Db.db.rawQuery(
        'SELECT i.*, '
            'c.name AS cand_name, '
            'j.title AS job_title, '
            '(SELECT name FROM employees x '
            'WHERE x.id = i.interviewer_id) AS interviewer_name '
            'FROM interviews i '
            'INNER JOIN candidates c ON c.id = i.candidate_id '
            'LEFT JOIN jobs j ON j.id = c.job_id '
            "WHERE c.stage = 'Interview' "
            'ORDER BY i.scheduled_at DESC',
      ),
    );

    return raw.map((r) => InterviewEntity.fromMap(r)).toList();
  }

  Future<List<InterviewEntity>> fetchInterviews() => interviews();

  Future<List<InterviewEntity>> candidateInterviews(
      int candidateId,
      ) async {
    final raw = await Repo.queryOrLocal(
      'candidate_interviews',
      {
        'candidate_id': '$candidateId',
      },
          () => Db.db.rawQuery(
        'SELECT i.*, '
            '(SELECT name FROM employees x '
            'WHERE x.id = i.interviewer_id) AS interviewer_name '
            'FROM interviews i '
            'WHERE i.candidate_id = ? '
            'ORDER BY i.scheduled_at DESC',
        [candidateId],
      ),
    );

    return raw.map((r) => InterviewEntity.fromMap(r)).toList();
  }

  Future<List<InterviewEntity>> fetchCandidateInterviews(
      int candidateId,
      ) {
    return candidateInterviews(candidateId);
  }

  Future<void> saveInterview(
      Object data, {
        int? id,
      }) async {
    final map = data is InterviewEntity
        ? data.toMap()
        : Map<String, Object?>.from(data as Map);

    if (id == null) {
      // Create interview.
      await Repo.saveData('interviews', {}, map);

      // Move shortlisted candidate to Interview stage.
      await Db.db.rawUpdate(
        "UPDATE candidates "
            "SET stage = 'Interview', stage_changed_on = ? "
            "WHERE id = ? AND stage = 'Shortlisted'",
        [
          ymd(DateTime.now()),
          map['candidate_id'],
        ],
      );
    } else {
      // Update existing interview.
      await Repo.saveData(
        'interviews',
        {'id': '$id'},
        map,
      );
    }
  }

  Future<void> setInterviewResult(
      int id,
      String result,
      String feedback,
      ) async {
    await Db.db.update(
      'interviews',
      {
        'result': result,
        'feedback': feedback,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteInterview(int id) {
    return Repo.deleteData(
      'interviews',
      {'id': '$id'},
    );
  }

  // ---------------------------------------------------------------------------
  // DASHBOARD STATISTICS
  // ---------------------------------------------------------------------------

  Future<Map<String, int>> recruitmentStats() async {
    final now = DateTime.now();

    final openJobs = await LocalDatasource.dbCount(
      "SELECT COUNT(*) FROM jobs "
          "WHERE approval = 'Approved' AND status = 'Open'",
    );

    final pendingJobs = await LocalDatasource.dbCount(
      "SELECT COUNT(*) FROM jobs WHERE approval = 'Pending'",
    );

    final candidatesCount = await LocalDatasource.dbCount(
      "SELECT COUNT(*) FROM candidates "
          "WHERE stage NOT IN ('Hired', 'Rejected')",
    );

    // Same filtered source as the interview list.
    final interviewList = await interviews();

    final hiredCount = await LocalDatasource.dbCount(
      "SELECT COUNT(*) FROM candidates "
          "WHERE stage = 'Hired' "
          "AND substr(stage_changed_on, 1, 7) = ?",
      [
        monthKey(now.year, now.month),
      ],
    );

    return {
      'openJobs': openJobs,
      'pendingJobs': pendingJobs,
      'candidates': candidatesCount,
      'interviews': interviewList.length,
      'hired': hiredCount,
    };
  }

  Future<Map<String, int>> fetchRecruitmentStats() {
    return recruitmentStats();
  }
}
