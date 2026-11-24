import 'package:flutter/foundation.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import '../data/employees_repository.dart';

class EmployeesController extends ChangeNotifier {
  final EmployeesRepository _repository = EmployeesRepository();

  List<EmployeeEntity> rows = [];

  String searchQuery = '';

  bool isLoading = false;
  int _requestNumber = 0;
  bool _disposed = false;

  Future<void> loadEmployees() async {
    if (_disposed) return;

    final request = ++_requestNumber;
    isLoading = true;
    notifyListeners();

    try {

      final result = await _repository.fetchEmployees(
        q: searchQuery,
      );

      if (_disposed || request != _requestNumber) return;

      rows = result;
    } finally {
      if (!_disposed && request == _requestNumber) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void setSearchQuery(String query) {
    searchQuery = query.trim();

    loadEmployees().catchError((Object error, StackTrace stackTrace) {
      debugPrint('SEARCH EMPLOYEES ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _requestNumber++;
    super.dispose();
  }
}
