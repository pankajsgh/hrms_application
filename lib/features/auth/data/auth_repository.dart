import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/session.dart';

class AuthRepository {
  Future<bool> login(String username, String password) async {
    final rows = await Db.db.query('users',
        where: 'username = ? COLLATE NOCASE AND active = 1',
        whereArgs: [username.trim()]);
    if (rows.isEmpty) return false;
    final u = rows.first;
    if (!checkPassword(password, u.s('password'))) return false;
    Rec? e;
    final eid = u.i('employee_id');
    if (eid != null) {
      final er =
          await Db.db.query('employees', where: 'id = ?', whereArgs: [eid]);
      if (er.isNotEmpty) e = Map.of(er.first);
      if (e != null && e['status'] == 'Inactive') return false;
    }
    Session.set(Map.of(u), e);
    return true;
  }
}
