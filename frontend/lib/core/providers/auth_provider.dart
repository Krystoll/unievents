import 'package:flutter/foundation.dart';

import '../api/api_json.dart';
import '../api/auth_service.dart';
import '../storage/token_storage.dart';
import '../../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _error;
  String? _token;
  User? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  String? get role => _user?.role;
  User? get user => _user;

  Future<void> init() async {
    _token = await TokenStorage.getToken();
    if (_token != null) {
      try {
        _user = await _authService.me();
        await TokenStorage.saveRole(_user!.role);
      } catch (_) {
        final role = await TokenStorage.getRole();
        if (role != null) {
          _user = User(id: '', name: '', email: '', role: role, reliabilityScore: 0);
        }
      }
    }
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _authService.login(email: email, password: password);
      _token = response.token;
      _user = response.user;
      await TokenStorage.saveToken(response.token);
      await TokenStorage.saveRole(response.user.role);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      _token = response.token;
      _user = response.user;
      await TokenStorage.saveToken(response.token);
      await TokenStorage.saveRole(response.user.role);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    _token = null;
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) => extractApiErrorMessage(error);
}
