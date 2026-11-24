import 'package:flutter/foundation.dart';
import 'package:hrms/features/auth/data/login_request.dart';
import '../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  bool busy = false;
  String? error;

  Future<bool> login(String user_name, String pass_word) async {
    busy = true;
    error = null;
    notifyListeners();

    var loginRequest = LoginRequest(username: user_name, password: pass_word);
    final ok = await _repository.login(loginRequest);

    busy = false;
    if (!ok) {
      error = 'Invalid username or password';
    }
    notifyListeners();
    return ok;
  }
}
