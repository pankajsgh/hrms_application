
import 'package:flutter/foundation.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:hrms/domain/entities/special_day_entity.dart';

import '../data/special_days_repository.dart';

class SpecialDaysController extends ChangeNotifier {
  final SpecialDaysRepository _repository = SpecialDaysRepository();

  bool isLoading = false;
  String? error;

  List<SpecialDayEntity> specialDays = [];
  List<EmployeeEntity> activeEmployees = [];

  String selectedKind = 'All';

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  List<SpecialDayEntity> get filteredSpecialDays {
    if (_normalize(selectedKind) == 'all') {
      return specialDays;
    }

    return specialDays.where((item) {
      return _normalize(item.kind) == _normalize(selectedKind);
    }).toList();
  }

  Future<void> loadSpecialDays() async {
    if (isLoading) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final days = await _repository.fetchSpecialDays();
      final employees = await _repository.fetchActiveEmployees();

      specialDays = days;
      activeEmployees = employees;
    } catch (e, stack) {
      error = e.toString();
      debugPrint('Special days loading error: $e');
      debugPrintStack(stackTrace: stack);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedKind(String kind) {
    if (selectedKind == kind) return;

    selectedKind = kind;
    notifyListeners();
  }

  Future<void> saveSpecialDay(
      Object data, {
        int? id,
      }) async {
    await _repository.saveSpecialDay(data, id: id);
    await loadSpecialDays();
  }

  Future<void> deleteSpecialDay(int id) async {
    await _repository.deleteSpecialDay(id);
    await loadSpecialDays();
  }
}
