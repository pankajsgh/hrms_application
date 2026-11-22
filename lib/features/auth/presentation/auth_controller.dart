import 'package:flutter/foundation.dart';
import '../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  bool busy = false;
  String? error;

  Future<bool> login(String username, String password) async {
    busy = true;
    error = null;
    notifyListeners();

    final ok = await _repository.login(username, password);

    busy = false;
    if (!ok) {
      error = 'Invalid username or password';
    }
    notifyListeners();
    return ok;
  }
}
