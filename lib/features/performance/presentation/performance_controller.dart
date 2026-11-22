import 'package:flutter/foundation.dart';
import 'package:hrms/core/common.dart';
import '../data/performance_repository.dart';

class PerformanceController extends ChangeNotifier {
  final PerformanceRepository _repository = PerformanceRepository();

  bool isLoading = false;
  List<Rec> goals = [];
  List<Rec> reviews = [];

  Future<void> loadPerformance() async {
    isLoading = true;
    notifyListeners();

    goals = await _repository.fetchGoals();
    reviews = await _repository.fetchReviews();

    isLoading = false;
    notifyListeners();
  }

  Future<void> saveGoal(Rec data, {int? id}) async {
    await _repository.saveGoal(data, id: id);
    await loadPerformance();
  }

  Future<void> deleteGoal(int id) async {
    await _repository.deleteGoal(id);
    await loadPerformance();
  }

  Future<void> saveReview(Rec data) async {
    await _repository.saveReview(data);
    await loadPerformance();
  }

  Future<void> deleteReview(int id) async {
    await _repository.deleteReview(id);
    await loadPerformance();
  }
}
