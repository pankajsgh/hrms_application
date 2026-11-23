import 'package:flutter/foundation.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:hrms/domain/entities/special_day_entity.dart';
import '../data/special_days_repository.dart';

class SpecialDaysController extends ChangeNotifier {
  final SpecialDaysRepository _repository = SpecialDaysRepository();

  bool isLoading = false;
  List<SpecialDayEntity> specialDays = [];
  List<EmployeeEntity> activeEmployees = [];
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

  Future<void> saveSpecialDay(SpecialDayEntity data, {int? id}) async {
    await _repository.saveSpecialDay(data, id: id);
    await loadSpecialDays();
  }

  Future<void> deleteSpecialDay(int id) async {
    await _repository.deleteSpecialDay(id);
    await loadSpecialDays();
  }
}
