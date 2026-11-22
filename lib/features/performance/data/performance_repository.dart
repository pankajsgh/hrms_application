import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/repo.dart';

class PerformanceRepository {
  Future<List<Rec>> goals() async {
    return queryOrLocal('goals', {}, () async {
      final ids = await scopeIds();
      return Db.db.rawQuery(
          'SELECT g.*, e.name AS emp_name FROM goals g '
          'JOIN employees e ON e.id = g.employee_id '
          '${ids == null ? '' : 'WHERE g.employee_id IN ${dbIn(ids)}'} '
          'ORDER BY g.id DESC');
    });
  }

  Future<List<Rec>> fetchGoals() => goals();

  Future<void> saveGoal(Rec data, {int? id}) async {
    await saveData('goals', id != null ? {'id': '$id'} : {}, data);
  }

  Future<void> deleteGoal(int id) => deleteData('goals', {'id': '$id'});

  Future<List<Rec>> reviews() async {
    return queryOrLocal('reviews', {}, () async {
      final ids = await scopeIds();
      return Db.db.rawQuery(
          'SELECT r.*, e.name AS emp_name, '
          '(SELECT name FROM employees x WHERE x.id = r.reviewer_id) AS reviewer_name '
          'FROM reviews r JOIN employees e ON e.id = r.employee_id '
          '${ids == null ? '' : 'WHERE r.employee_id IN ${dbIn(ids)}'} '
          'ORDER BY r.id DESC');
    });
  }

  Future<List<Rec>> fetchReviews() => reviews();

  Future<void> saveReview(Rec data) => saveData('reviews', {}, data);

  Future<void> deleteReview(int id) => deleteData('reviews', {'id': '$id'});
}
