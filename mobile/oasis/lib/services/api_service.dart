import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oasis/models/track.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api/v1';

  Future<List<Track>> search(String query, {int offset = 0}) async {
    final response = await http.get(Uri.parse('$_baseUrl/search?query=$query&offset=$offset'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      List<Track> tracks = body.map((dynamic item) => Track.fromJson(item)).toList();
      return tracks;
    } else {
      throw Exception('Failed to load tracks');
    }
  }

  Future<String> getStreamUrl(int trackId) async {
    final response = await http.get(Uri.parse('$_baseUrl/stream/$trackId'));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['url'];
    } else {
      throw Exception('Failed to load stream URL');
    }
  }
}