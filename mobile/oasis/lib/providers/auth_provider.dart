import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oasis/models/user.dart';
import 'package:oasis/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  User? _currentUser; // Храним данные пользователя

  bool get isAuthenticated => _isAuthenticated;

  User? get currentUser => _currentUser;

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  AuthProvider() {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      _isAuthenticated = true;
      // При старте приложения загружаем профиль
      await _loadProfile();
    } else {
      _isAuthenticated = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  // Внутренний метод загрузки профиля
  Future<void> _loadProfile() async {
    try {
      _currentUser = await _apiService.getUserProfile();
    } catch (e) {
      print("Error loading profile: $e");
      if (e.toString().contains("401") ||
          e.toString().contains("Session expired")) {
        await logout();
      }
    }
  }

  Future<void> performSafeCall(Future<void> Function() apiCall) async {
    try {
      await apiCall();
    } catch (e) {
      if (e.toString().contains('Session expired') ||
          e.toString().contains('401')) {
        await logout();
      } else {
        rethrow;
      }
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      await _saveTokens(response.accessToken, response.refreshToken);
      _isAuthenticated = true;

      await _loadProfile();

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

      await _loadProfile();

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _saveTokens(String access, String? refresh) async {
    await _storage.write(key: 'access_token', value: access);
    if (refresh != null) {
      await _storage.write(key: 'refresh_token', value: refresh);
    }
  }
}
