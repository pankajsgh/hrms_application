
import 'package:hrms/core/db.dart';
import 'package:hrms/data/datasources/local_datasource.dart';
import 'package:hrms/data/repositories/repository_impl.dart';
import 'package:hrms/domain/entities/performance_entity.dart';

class PerformanceRepository {
  Future<List<GoalEntity>> goals() async {
    final raw = await Repo.queryOrLocal('goals', {}, () async {
      final ids = await scopeIds();

      return Db.db.rawQuery(
        'SELECT g.*, e.name AS emp_name FROM goals g '
            'JOIN employees e ON e.id = g.employee_id '
            '${ids == null ? '' : 'WHERE g.employee_id IN ${LocalDatasource.dbIn(ids)}'} '
            'ORDER BY g.id DESC',
      );
    });

    return raw.map((r) => GoalEntity.fromMap(r)).toList();
  }

  Future<List<GoalEntity>> fetchGoals() => goals();

  Future<void> saveGoal(Object data, {int? id}) async {
    final map = data is GoalEntity
        ? data.toMap()
        : Map<String, Object?>.from(data as Map);

    await Repo.saveData(
      'goals',
      id != null ? {'id': '$id'} : {},
      map,
    );
  }

  Future<void> deleteGoal(int id) =>
      Repo.deleteData('goals', {'id': '$id'});

  Future<List<ReviewEntity>> reviews() async {
    final raw = await Repo.queryOrLocal('reviews', {}, () async {
      final ids = await scopeIds();

      return Db.db.rawQuery(
        'SELECT r.*, e.name AS emp_name, '
            '(SELECT name FROM employees x WHERE x.id = r.reviewer_id) AS reviewer_name '
            'FROM reviews r JOIN employees e ON e.id = r.employee_id '
            '${ids == null ? '' : 'WHERE r.employee_id IN ${LocalDatasource.dbIn(ids)}'} '
            'ORDER BY r.id DESC',
      );
    });

    return raw.map((r) => ReviewEntity.fromMap(r)).toList();
  }

  Future<List<ReviewEntity>> fetchReviews() => reviews();

  Future<void> saveReview(Object data) async {
    final map = data is ReviewEntity
        ? data.toMap()
        : Map<String, Object?>.from(data as Map);

    await Repo.saveData('reviews', {}, map);
  }

  Future<void> deleteReview(int id) =>
      Repo.deleteData('reviews', {'id': '$id'});
}
