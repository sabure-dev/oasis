import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oasis/models/track.dart';
import 'package:oasis/models/auth_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment('BACKEND_URL', defaultValue: 'http://localhost:8000/api/v1');
  final _storage = const FlutterSecureStorage();

  // Флаг, чтобы не запускать несколько рефрешей одновременно
  bool _isRefreshing = false;

  // --- Auth Methods ---

  Future<AuthResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final authData = AuthResponse.fromJson(jsonDecode(response.body));
      // ВАЖНО: Сохраняем пароль для будущего рефреша
      await _saveCredentials(authData, password);
      return authData;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<AuthResponse> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final authData = AuthResponse.fromJson(jsonDecode(response.body));
      await _saveCredentials(authData, password);
      return authData;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    // Опционально: дернуть ручку logout на бэкенде
    await _storage.deleteAll();
  }

  // --- Internal Helpers ---

  Future<void> _saveCredentials(AuthResponse authData, String password) async {
    await _storage.write(key: 'access_token', value: authData.accessToken);
    await _storage.write(key: 'refresh_token', value: authData.refreshToken);
    await _storage.write(key: 'password', value: password); // Храним пароль безопасно
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Главная магия: Обертка для запросов с автоматическим рефрешем
  Future<http.Response> _performRequest(Future<http.Response> Function() requestCaller) async {
    // 1. Делаем исходный запрос
    var response = await requestCaller();

    // 2. Если получили 401 (Unauthorized) и мы еще не в процессе рефреша
    if (response.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        // 3. Пытаемся обновить токен
        final success = await _refreshToken();
        if (success) {
          // 4. Если успешно — повторяем исходный запрос (он подтянет новый токен в _getHeaders)
          response = await requestCaller();
        }
      } catch (e) {
        // Если рефреш упал (например, пароль сменили или refresh token протух)
        // Пробрасываем ошибку дальше, чтобы UI мог разлогинить юзера
        rethrow;
      } finally {
        _isRefreshing = false;
      }
    }

    return response;
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    final password = await _storage.read(key: 'password');

    if (refreshToken == null || password == null) return false;

    try {
      // Используем ваш эндпоинт, который требует пароль
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refresh_token': refreshToken,
          'password': password
        }),
      );

      if (response.statusCode == 200) {
        final newTokens = AuthResponse.fromJson(jsonDecode(response.body));
        // Обновляем всё в хранилище (пароль остается старый)
        await _saveCredentials(newTokens, password);
        return true;
      } else {
        // Если рефреш не удался (например, 401 или 500) -> считаем сессию мертвой
        await logout();
        return false;
      }
    } catch (e) {
      await logout();
      return false;
    }
  }

  // --- Data Methods (используют _performRequest) ---

  Future<List<Track>> search(String query, {int offset = 0}) async {
    // Оборачиваем запрос в лямбду, чтобы _performRequest мог вызвать его дважды при необходимости
    final response = await _performRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse('$_baseUrl/music/search?query=$query&offset=$offset'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((item) => Track.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expired'); // Это поймает UI и перекинет на логин
    } else {
      throw Exception('Failed to load tracks: ${response.statusCode}');
    }
  }

  Future<String> getStreamUrl(int trackId) async {
    final response = await _performRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse('$_baseUrl/music/stream/$trackId'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['url'];
    } else {
      throw Exception('Failed to load stream URL');
    }
  }
}