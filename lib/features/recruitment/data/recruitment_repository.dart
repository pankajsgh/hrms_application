import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/data/datasources/local_datasource.dart';
import 'package:hrms/data/repositories/repository_impl.dart';

class RecruitmentRepository {
  Future<List<Rec>> jobs() => Repo.queryOrLocal('jobs', {}, () => Db.db.rawQuery(
      'SELECT j.*, '
      '(SELECT COUNT(*) FROM candidates c WHERE c.job_id = j.id) AS cands, '
      '(SELECT name FROM employees x WHERE x.id = j.created_by) AS creator_name '
      'FROM jobs j '
      "ORDER BY CASE j.approval WHEN 'Pending' THEN 0 ELSE 1 END, j.id DESC"));

  Future<List<Rec>> fetchJobs() => jobs();

  Future<int> createJob(Rec data) {
    final admin = Session.isAdmin;
    final now = ymd(DateTime.now());
    return Repo.saveData('jobs', {}, {
      ...data,
      'created_by': Session.empId,
      'created_on': now,
      'approval': admin ? 'Approved' : 'Pending',
      if (admin) 'approved_by': Session.empId,
      if (admin) 'approved_on': now,
    });
  }

  Future<void> updateJob(int id, Rec data, {String? currentApproval}) async {
    final v = <String, Object?>{...data};
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

  Future<List<Rec>> candidates({int? jobId, String q = ''}) {
    final queryMap = <String, String>{
      if (jobId != null) 'job_id': '$jobId',
      'q': q,
    };
    return Repo.queryOrLocal('candidates', queryMap, () async {
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
  }

  Future<List<Rec>> fetchCandidates({int? jobId, String q = ''}) =>
      candidates(jobId: jobId, q: q);

  Future<void> saveCandidate(Rec data, {int? id}) async {
    await Repo.saveData('candidates', id != null ? {'id': '$id'} : {}, data);
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

  Future<List<Rec>> interviews() => Repo.queryOrLocal('interviews', {}, () => Db.db.rawQuery(
      'SELECT i.*, c.name AS cand_name, j.title AS job_title, '
      '(SELECT name FROM employees x WHERE x.id = i.interviewer_id) AS interviewer_name '
      'FROM interviews i JOIN candidates c ON c.id = i.candidate_id '
      'JOIN jobs j ON j.id = c.job_id ORDER BY i.scheduled_at DESC'));

  Future<List<Rec>> fetchInterviews() => interviews();

  Future<List<Rec>> candidateInterviews(int candidateId) =>
      Repo.queryOrLocal('candidate_interviews', {'candidate_id': '$candidateId'}, () => Db.db.rawQuery(
          'SELECT i.*, (SELECT name FROM employees x WHERE x.id = i.interviewer_id) '
          'AS interviewer_name FROM interviews i WHERE i.candidate_id = ? '
          'ORDER BY i.scheduled_at DESC',
          [candidateId]));

  Future<List<Rec>> fetchCandidateInterviews(int candidateId) =>
      candidateInterviews(candidateId);

  Future<void> saveInterview(Rec data, {int? id}) async {
    if (id == null) {
      await Repo.saveData('interviews', {}, data);
      await Db.db.rawUpdate(
          "UPDATE candidates SET stage = 'Interview', stage_changed_on = ? "
          "WHERE id = ? AND stage IN ('Applied','Screening')",
          [ymd(DateTime.now()), data['candidate_id']]);
    } else {
      await Repo.saveData('interviews', {'id': '$id'}, data);
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
