import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oasis/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isLoading = true; // Для показа сплэш-экрана при запуске
  bool get isLoading => _isLoading;

  AuthProvider() {
    checkAuth();
  }

Future<void> checkAuth() async {
  final token = await _storage.read(key: 'access_token');
  // Мы можем дополнительно проверить валидность токена,
  // но проще считать пользователя залогиненным, пока не придет 401, который мы не сможем "починить".
  if (token != null) {
    _isAuthenticated = true;
  } else {
    _isAuthenticated = false;
  }
  _isLoading = false;
  notifyListeners();
}

// Обертка для вызова методов API из UI
Future<void> performSafeCall(Future<void> Function() apiCall) async {
  try {
    await apiCall();
  } catch (e) {
    // Если ApiService выбросил 'Session expired' (значит рефреш не сработал)
    if (e.toString().contains('Session expired')) {
      await logout(); // Чистим стейт и перекидываем на экран логина
    } else {
      rethrow; // Остальные ошибки (нет интернета и т.д.) показываем юзеру
    }
  }
}

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      await _saveTokens(response.accessToken, response.refreshToken);
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      final response = await _apiService.register(username, email, password);
      await _saveTokens(response.accessToken, response.refreshToken);
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }
}