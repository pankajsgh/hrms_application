import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/repo.dart';
import '../../employees/data/employees_repository.dart';

class DocumentsRepository {
  Future<List<Rec>> documents() async {
    return queryOrLocal('documents', {}, () async {
      final ids = await scopeIds();
      return Db.db.rawQuery(
          'SELECT d.*, e.name AS emp_name FROM documents d '
          'JOIN employees e ON e.id = d.employee_id '
          '${ids == null ? '' : 'WHERE d.employee_id IN ${dbIn(ids)}'} '
          'ORDER BY d.id DESC');
    });
  }

  Future<List<Rec>> fetchDocuments() => documents();

  Future<void> addDocument(
      int emp, String title, String category, String source) async {
    final base = await getApplicationSupportDirectory();
    final folder = Directory(p.join(base.path, 'documents', '$emp'));
    await folder.create(recursive: true);
    final dest = p.join(folder.path,
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(source)}');
    await File(source).copy(dest);
    await saveData('documents', {}, {
      'employee_id': emp,
      'title': title,
      'category': category,
      'file_path': dest,
      'added_on': ymd(DateTime.now()),
    });
  }

  Future<void> deleteDocument(Rec doc) async {
    final f = File(doc.s('file_path'));
    if (await f.exists()) await f.delete();
    await deleteData('documents', {'id': '${doc['id']}'});
  }

  Future<List<Rec>> scopeEmployees() => EmployeesRepository().scopeEmployees();

  Future<List<Rec>> fetchScopeEmployees() => scopeEmployees();
}
