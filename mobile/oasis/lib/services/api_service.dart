import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:oasis/models/auth_models.dart';
import 'package:oasis/models/track.dart';

import '../models/user.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment('BACKEND_URL',
      defaultValue: 'http://localhost:8000/api/v1');
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
      await _saveCredentials(authData);
      return authData;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<AuthResponse> register(
      String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'username': username, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final authData = AuthResponse.fromJson(jsonDecode(response.body));
      await _saveCredentials(authData);
      return authData;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // --- Internal Helpers ---

  Future<void> _saveCredentials(AuthResponse authData) async {
    await _storage.write(key: 'access_token', value: authData.accessToken);
    if (authData.refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: authData.refreshToken!);
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _performRequest(
      Future<http.Response> Function() requestCaller) async {
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

    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refresh_token': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final newTokens = AuthResponse.fromJson(jsonDecode(response.body));
        await _saveCredentials(newTokens);
        return true;
      } else {
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

  Future<User> getUserProfile() async {
    final response = await _performRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load profile, status=${response.statusCode}');
    }
  }

  Future<void> requestVerification() async {
    final response = await _performRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse('$_baseUrl/auth/verify/request'),
        headers: headers,
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to send code: ${response.body}');
    }
  }

  Future<void> confirmVerification(String code) async {
    final response = await _performRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse('$_baseUrl/auth/verify/confirm'),
        headers: headers,
        body: jsonEncode({'code': code}),
      );
    });

    if (response.statusCode != 200) {
      throw Exception('Verification failed: ${response.body}');
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          jsonDecode(response.body)['detail'] ?? 'Failed to send code');
    }
  }

  Future<void> resetPassword(
      String email, String code, String newPassword) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'email': email, 'code': code, 'new_password': newPassword}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          jsonDecode(response.body)['detail'] ?? 'Failed to reset password');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPlaylistsRaw() async {
    final response = await _performRequest(() async {
      final headers = await _getHeaders();
      return http.get(Uri.parse('$_baseUrl/music/playlists'), headers: headers);
    });

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
          jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to fetch playlists');
    }
  }

  Future<int> createPlaylist(String name) async {
    final response = await _performRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse('$_baseUrl/music/playlists'),
        headers: headers,
        body: jsonEncode({'name': name}),
      );
    });

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['id'];
    }
    throw Exception('Failed to create playlist');
  }

  Future<void> deletePlaylist(int remoteId) async {
    await _performRequest(() async {
      final headers = await _getHeaders();
      return http.delete(Uri.parse('$_baseUrl/music/playlists/$remoteId'),
          headers: headers);
    });
  }

  Future<void> addTrackToPlaylist(int playlistRemoteId, Track track) async {
    await _performRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse('$_baseUrl/music/playlists/$playlistRemoteId/tracks'),
        headers: headers,
        body: jsonEncode({
          'id': track.id,
          'title': track.title,
          'artist': track.artist,
          'album': track.album,
          'album_cover': track.albumCover,
          'duration': track.duration,
        }),
      );
    });
  }

  Future<void> removeTrackFromPlaylist(
      int playlistRemoteId, int trackId) async {
    await _performRequest(() async {
      final headers = await _getHeaders();
      return http.delete(
        Uri.parse(
            '$_baseUrl/music/playlists/$playlistRemoteId/tracks/$trackId'),
        headers: headers,
      );
    });
  }
}
