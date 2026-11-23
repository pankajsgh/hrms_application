import 'dart:io';
import 'package:hrms/data/datasources/local_datasource.dart';
import 'package:hrms/data/repositories/repository_impl.dart';
import 'package:hrms/domain/entities/document_entity.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import '../../employees/data/employees_repository.dart';

class DocumentsRepository {
  Future<List<DocumentEntity>> documents() async {
    final raw = await Repo.queryOrLocal('documents', {}, () async {
      final ids = await scopeIds();
      return Db.db.rawQuery(
          'SELECT d.*, e.name AS emp_name FROM documents d '
          'JOIN employees e ON e.id = d.employee_id '
          '${ids == null ? '' : 'WHERE d.employee_id IN ${LocalDatasource.dbIn(ids)}'} '
          'ORDER BY d.id DESC');
    });
    return raw.map((r) => DocumentEntity.fromMap(r)).toList();
  }

  Future<List<DocumentEntity>> fetchDocuments() => documents();

  Future<void> addDocument(
      int emp, String title, String category, String source) async {
    final base = await getApplicationSupportDirectory();
    final folder = Directory(p.join(base.path, 'documents', '$emp'));
    await folder.create(recursive: true);
    final dest = p.join(folder.path,
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(source)}');
    await File(source).copy(dest);
    await Repo.saveData('documents', {}, {
      'employee_id': emp,
      'title': title,
      'category': category,
      'file_path': dest,
      'added_on': ymd(DateTime.now()),
    });
  }

  Future<void> deleteDocument(DocumentEntity doc) async {
    final f = File(doc.filePath);
    if (await f.exists()) await f.delete();
    if (doc.id != null) {
      await Repo.deleteData('documents', {'id': '${doc.id}'});
    }
  }

  Future<List<EmployeeEntity>> scopeEmployees() => EmployeesRepository().scopeEmployees();

  Future<List<EmployeeEntity>> fetchScopeEmployees() => scopeEmployees();
}
