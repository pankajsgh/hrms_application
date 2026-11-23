import 'package:flutter/foundation.dart';
import 'package:hrms/domain/entities/performance_entity.dart';
import '../data/performance_repository.dart';

class PerformanceController extends ChangeNotifier {
  final PerformanceRepository _repository = PerformanceRepository();

  bool isLoading = false;
  List<GoalEntity> goals = [];
  List<ReviewEntity> reviews = [];

  Future<void> loadPerformance() async {
    isLoading = true;
    notifyListeners();

    goals = await _repository.fetchGoals();
    reviews = await _repository.fetchReviews();

    isLoading = false;
    notifyListeners();
  }

  Future<void> saveGoal(GoalEntity data, {int? id}) async {
    await _repository.saveGoal(data, id: id);
    await loadPerformance();
  }

  Future<void> deleteGoal(int id) async {
    await _repository.deleteGoal(id);
    await loadPerformance();
  }

  Future<void> saveReview(ReviewEntity data) async {
    await _repository.saveReview(data);
    await loadPerformance();
  }

  Future<void> deleteReview(int id) async {
    await _repository.deleteReview(id);
    await loadPerformance();
  }
}
