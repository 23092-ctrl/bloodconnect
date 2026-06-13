import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/storage/local_storage.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  final AuthService _service;

  AuthController(this._service);

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  Future<void> checkAuth() async {
    if (!LocalStorage.isAuthenticated) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final user = await _service.getProfile();
      _user = user;
      _status = AuthStatus.authenticated;
    } catch (_) {
      await LocalStorage.clear();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.login(email: email, password: password);
      await LocalStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await LocalStorage.saveUser(result.user.toJson());
      _user = result.user;
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _parseError(e);
    }
    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? bloodType,
    String? gender,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.register(
        fullName: fullName,
        email: email,
        password: password,
        bloodType: bloodType,
        gender: gender,
        phone: phone,
      );
      await LocalStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await LocalStorage.saveUser(result.user.toJson());
      _user = result.user;
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _parseError(e);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await LocalStorage.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _service.getProfile();
      await LocalStorage.saveUser(user.toJson());
      _user = user;
      notifyListeners();
    } catch (_) {}
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    final str = e.toString();
    if (str.contains('401')) return 'Invalid email or password';
    if (str.contains('409')) return 'Email already registered';
    return 'Something went wrong. Please try again.';
  }
}
