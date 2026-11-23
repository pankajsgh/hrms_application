import 'package:flutter/foundation.dart';
import 'package:hrms/domain/entities/document_entity.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import '../data/documents_repository.dart';

class DocumentsController extends ChangeNotifier {
  final DocumentsRepository _repository = DocumentsRepository();

  bool isLoading = false;
  List<DocumentEntity> documents = [];
  List<EmployeeEntity> scopeEmployees = [];

  Future<void> loadDocuments() async {
    isLoading = true;
    notifyListeners();

    documents = await _repository.fetchDocuments();
    scopeEmployees = await _repository.fetchScopeEmployees();

    isLoading = false;
    notifyListeners();
  }

  Future<void> addDocument(int emp, String title, String category, String filePath) async {
    await _repository.addDocument(emp, title, category, filePath);
    await loadDocuments();
  }

  Future<void> deleteDocument(DocumentEntity doc) async {
    await _repository.deleteDocument(doc);
    await loadDocuments();
  }
}
