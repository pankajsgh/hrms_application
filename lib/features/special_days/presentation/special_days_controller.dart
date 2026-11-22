import 'package:flutter/foundation.dart';
import 'package:hrms/core/common.dart';
import '../data/special_days_repository.dart';

class SpecialDaysController extends ChangeNotifier {
  final SpecialDaysRepository _repository = SpecialDaysRepository();

  bool isLoading = false;
  List<Rec> specialDays = [];
  List<Rec> activeEmployees = [];
  String selectedKind = 'All';

  Future<void> loadSpecialDays() async {
    isLoading = true;
    notifyListeners();

    specialDays = await _repository.fetchSpecialDays();
    activeEmployees = await _repository.fetchActiveEmployees();

    isLoading = false;
    notifyListeners();
  }

  void setSelectedKind(String kind) {
    selectedKind = kind;
    notifyListeners();
  }

  Future<void> saveSpecialDay(Rec data, {int? id}) async {
    await _repository.saveSpecialDay(data, id: id);
    await loadSpecialDays();
  }

  Future<void> deleteSpecialDay(int id) async {
    await _repository.deleteSpecialDay(id);
    await loadSpecialDays();
  }
}
