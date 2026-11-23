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
  Future<List<JobEntity>> jobs() async {
    final raw = await Repo.queryOrLocal('jobs', {}, () => Db.db.rawQuery(
        'SELECT j.*, '
        '(SELECT COUNT(*) FROM candidates c WHERE c.job_id = j.id) AS cands, '
        '(SELECT name FROM employees x WHERE x.id = j.created_by) AS creator_name '
        'FROM jobs j '
        "ORDER BY CASE j.approval WHEN 'Pending' THEN 0 ELSE 1 END, j.id DESC"));
    return raw.map((r) => JobEntity.fromMap(r)).toList();
  }

  Future<List<JobEntity>> fetchJobs() => jobs();

  Future<int> createJob(Object data) {
    final map = data is JobEntity ? data.toMap() : (data as Map<String, Object?>);
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

  Future<void> updateJob(int id, Object data, {String? currentApproval}) async {
    final map = data is JobEntity ? data.toMap() : (data as Map<String, Object?>);
    final v = <String, Object?>{...map};
    if (currentApproval == 'Rejected' && !Session.isAdmin) {
      v['approval'] = 'Pending';
      v['reject_reason'] = null;
    }
    await Repo.saveData('jobs', {'id': '$id'}, v);
  }

  Future<void> decideJob(int id, bool approve, String reason) async {
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
        whereArgs: [id]);
  }

  Future<void> deleteJob(int id) async {
    final cands =
        await Db.db.query('candidates', columns: ['id'], where: 'job_id = ?', whereArgs: [id]);
    for (final c in cands) {
      await Repo.deleteData('interviews', {'candidate_id': '${c['id']}'});
    }
    await Repo.deleteData('candidates', {'job_id': '$id'});
    await Repo.deleteData('jobs', {'id': '$id'});
  }

  Future<List<CandidateEntity>> candidates({int? jobId, String q = ''}) async {
    final queryMap = <String, String>{
      if (jobId != null) 'job_id': '$jobId',
      'q': q,
    };
    final raw = await Repo.queryOrLocal('candidates', queryMap, () async {
      final w = <String>[];
      final a = <Object?>[ymd(DateTime.now())];
      if (jobId != null) {
        w.add('c.job_id = ?');
        a.add(jobId);
      }
      if (q.isNotEmpty) {
        w.add('(c.name LIKE ? OR c.email LIKE ? OR c.phone LIKE ?)');
        a.addAll(['%$q%', '%$q%', '%$q%']);
      }
      return Db.db.rawQuery(
          'SELECT c.*, j.title AS job_title, j.department AS job_department, '
          '(SELECT MIN(i.scheduled_at) FROM interviews i WHERE i.candidate_id = c.id '
          "AND i.result = 'Scheduled' AND i.scheduled_at >= ?) AS next_interview "
          'FROM candidates c JOIN jobs j ON j.id = c.job_id '
          '${w.isEmpty ? '' : 'WHERE ${w.join(' AND ')}'} '
          'ORDER BY c.id DESC',
          a);
    });
    return raw.map((r) => CandidateEntity.fromMap(r)).toList();
  }

  Future<List<CandidateEntity>> fetchCandidates({int? jobId, String q = ''}) =>
      candidates(jobId: jobId, q: q);

  Future<void> saveCandidate(Object data, {int? id}) async {
    final map = data is CandidateEntity ? data.toMap() : (data as Map<String, Object?>);
    await Repo.saveData('candidates', id != null ? {'id': '$id'} : {}, map);
  }

  Future<void> setStage(int id, String stage) => Db.db.update(
      'candidates', {'stage': stage, 'stage_changed_on': ymd(DateTime.now())},
      where: 'id = ?', whereArgs: [id]);

  Future<void> deleteCandidate(int id) async {
    await Repo.deleteData('interviews', {'candidate_id': '$id'});
    await Repo.deleteData('candidates', {'id': '$id'});
  }

  Future<void> attachResume(int id, String source) async {
    final base = await getApplicationSupportDirectory();
    final folder = Directory(p.join(base.path, 'resumes', '$id'));
    await folder.create(recursive: true);
    final dest = p.join(folder.path,
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(source)}');
    await File(source).copy(dest);
    await Db.db.update('candidates', {'resume_path': dest},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markConverted(int candidateId, int employeeId) =>
      Db.db.update(
          'candidates',
          {
            'converted_employee_id': employeeId,
            'stage': 'Hired',
            'stage_changed_on': ymd(DateTime.now()),
          },
          where: 'id = ?',
          whereArgs: [candidateId]);

  Future<List<InterviewEntity>> interviews() async {
    final raw = await Repo.queryOrLocal('interviews', {}, () => Db.db.rawQuery(
        'SELECT i.*, c.name AS cand_name, j.title AS job_title, '
        '(SELECT name FROM employees x WHERE x.id = i.interviewer_id) AS interviewer_name '
        'FROM interviews i JOIN candidates c ON c.id = i.candidate_id '
        'JOIN jobs j ON j.id = c.job_id ORDER BY i.scheduled_at DESC'));
    return raw.map((r) => InterviewEntity.fromMap(r)).toList();
  }

  Future<List<InterviewEntity>> fetchInterviews() => interviews();

  Future<List<InterviewEntity>> candidateInterviews(int candidateId) async {
    final raw = await Repo.queryOrLocal('candidate_interviews', {'candidate_id': '$candidateId'}, () => Db.db.rawQuery(
        'SELECT i.*, (SELECT name FROM employees x WHERE x.id = i.interviewer_id) '
        'AS interviewer_name FROM interviews i WHERE i.candidate_id = ? '
        'ORDER BY i.scheduled_at DESC',
        [candidateId]));
    return raw.map((r) => InterviewEntity.fromMap(r)).toList();
  }

  Future<List<InterviewEntity>> fetchCandidateInterviews(int candidateId) =>
      candidateInterviews(candidateId);

  Future<void> saveInterview(Object data, {int? id}) async {
    final map = data is InterviewEntity ? data.toMap() : (data as Map<String, Object?>);
    if (id == null) {
      await Repo.saveData('interviews', {}, map);
      await Db.db.rawUpdate(
          "UPDATE candidates SET stage = 'Interview', stage_changed_on = ? "
          "WHERE id = ? AND stage IN ('Applied','Screening')",
          [ymd(DateTime.now()), map['candidate_id']]);
    } else {
      await Repo.saveData('interviews', {'id': '$id'}, map);
    }
  }

  Future<void> setInterviewResult(int id, String result, String feedback) =>
      Db.db.update('interviews', {'result': result, 'feedback': feedback},
          where: 'id = ?', whereArgs: [id]);

  Future<void> deleteInterview(int id) => Repo.deleteData('interviews', {'id': '$id'});

  Future<Map<String, int>> recruitmentStats() async {
    final now = DateTime.now();
    return {
      'openJobs': await LocalDatasource.dbCount(
          "SELECT COUNT(*) FROM jobs WHERE approval = 'Approved' AND status = 'Open'"),
      'pendingJobs':
          await LocalDatasource.dbCount("SELECT COUNT(*) FROM jobs WHERE approval = 'Pending'"),
      'candidates': await LocalDatasource.dbCount(
          "SELECT COUNT(*) FROM candidates WHERE stage NOT IN ('Hired','Rejected')"),
      'interviews': await LocalDatasource.dbCount(
          "SELECT COUNT(*) FROM interviews WHERE result = 'Scheduled' AND scheduled_at >= ?",
          [ymd(now)]),
      'hired': await LocalDatasource.dbCount(
          "SELECT COUNT(*) FROM candidates WHERE stage = 'Hired' AND substr(stage_changed_on, 1, 7) = ?",
          [monthKey(now.year, now.month)]),
    };
  }

  Future<Map<String, int>> fetchRecruitmentStats() => recruitmentStats();
}
