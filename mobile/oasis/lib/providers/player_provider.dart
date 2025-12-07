import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:oasis/models/playlist.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/services/api_service.dart';
import 'package:path_provider/path_provider.dart';

class PlayerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Isar isar;

  Track? _currentTrack;
  List<Track> _currentPlaylist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;

  List<Playlist> _playlists = [];

  // Stream controller для отслеживания изменений в избранном
  final StreamController<List<int>> _favoritesController =
      StreamController<List<int>>.broadcast();

  Track? get currentTrack => _currentTrack;

  bool get isPlaying => _isPlaying;

  List<Playlist> get playlists => _playlists;

  AudioPlayer get audioPlayer => _audioPlayer;

  // Stream для отслеживания изменений в избранном
  Stream<List<int>> get favoritesStream => _favoritesController.stream;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  Stream<Duration> get bufferedPositionStream =>
      _audioPlayer.bufferedPositionStream;

  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  Stream<double> get volumeStream => _audioPlayer.volumeStream;

  PlayerProvider({required this.isar}) {
    _loadPlaylists();
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }

  Future<void> _loadPlaylists() async {
    final playlists = await isar.playlists.where().findAll();
    _playlists = playlists;
    if (_playlists.where((p) => p.name == 'Favorites').isEmpty) {
      final favorites = Playlist(
          id: Isar.autoIncrement,
          name: 'Favorites',
          trackIds: [],
          coverImage: '');
      await isar.writeTxn(() async {
        await isar.playlists.put(favorites);
      });
      // Обновляем _playlists после добавления в базу данных
      _playlists = await isar.playlists.where().findAll();
    }

    // Обновляем stream избранного
    _updateFavoritesStream();
    notifyListeners();
  }

  void _updateFavoritesStream() {
    final favoritesPlaylist =
        _playlists.firstWhere((p) => p.name == 'Favorites');
    _favoritesController.add(favoritesPlaylist.trackIds);
  }

  Future<void> play(Track track, {List<Track>? playlist}) async {
    _currentPlaylist = playlist ?? [track];
    _currentIndex = _currentPlaylist.indexWhere((t) => t.id == track.id);

    if (_currentTrack?.id == track.id && _isPlaying) {
      return;
    }

    try {
      await isar.writeTxn(() async {
        await isar.tracks.put(track);
      });
      if (track.localPath != null && await File(track.localPath!).exists()) {
        await _audioPlayer.setFilePath(
          track.localPath!,
          initialPosition: Duration.zero,
          preload: true,
          tag: MediaItem(
            id: track.id.toString(),
            album: track.album,
            title: track.title,
            artist: track.artist,
            artUri: Uri.parse(track.albumCover),
          ),
        );
      } else {
        final streamUrl = await _apiService.getStreamUrl(track.id);
        await _audioPlayer.setUrl(
          streamUrl,
          initialPosition: Duration.zero,
          preload: true,
          tag: MediaItem(
            id: track.id.toString(),
            album: track.album,
            title: track.title,
            artist: track.artist,
            artUri: Uri.parse(track.albumCover),
          ),
        );
      }

      _currentTrack = track;
      _audioPlayer.play();
      _isPlaying = true;
      notifyListeners();

      _audioPlayer.playingStream.listen((playing) {
        if (_isPlaying != playing) {
          _isPlaying = playing;
          notifyListeners();
        }
      });
    } catch (e) {
      print('Ошибка при воспроизведении: $e');
    }
  }

  void playNext() {
    if (_currentPlaylist.isNotEmpty &&
        _currentIndex < _currentPlaylist.length - 1) {
      _currentIndex++;
      play(_currentPlaylist[_currentIndex], playlist: _currentPlaylist);
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Track track) async {
    await _loadPlaylists(); // Обновляем плейлисты из БД

    final favoritesPlaylist =
        _playlists.firstWhere((p) => p.name == 'Favorites');
    final isFav = await isFavorite(track);

    // Создаем новый изменяемый список
    final trackIdsList = List<int>.from(favoritesPlaylist.trackIds);

    if (isFav) {
      trackIdsList.remove(track.id);
    } else {
      trackIdsList.add(track.id);
    }

    // Создаем новый плейлист с обновленным списком
    final updatedPlaylist = Playlist(
      id: favoritesPlaylist.id,
      name: favoritesPlaylist.name,
      coverImage: favoritesPlaylist.coverImage,
      trackIds: trackIdsList,
    );

    await isar.writeTxn(() async {
      await isar.playlists.put(updatedPlaylist);
    });

    // Обновляем локальный список плейлистов из БД
    _playlists = await isar.playlists.where().findAll();
    _updateFavoritesStream(); // Обновляем stream избранного
    notifyListeners();

    print('Favorite toggled for track: ${track.title}, isFavorite: ${!isFav}');
  }

  Future<bool> isFavorite(Track track) async {
    await _loadPlaylists(); // Обновляем плейлисты из БД

    final favoritesPlaylist =
        _playlists.firstWhere((p) => p.name == 'Favorites');
    return favoritesPlaylist.trackIds.contains(track.id);
  }

  Future<void> createPlaylist(String name) async {
    final newPlaylist = Playlist(
        id: Isar.autoIncrement, name: name, trackIds: [], coverImage: '');

    await isar.writeTxn(() async {
      await isar.playlists.put(newPlaylist);
    });

    // Обновляем локальный список плейлистов из БД
    _playlists = await isar.playlists.where().findAll();
    notifyListeners();

    print('Playlist created: $name');
  }

  Future<void> addTrackToPlaylist(Track track, Playlist playlist) async {
    try {
      // Сначала сохраняем трек в БД, если его там нет
      await isar.writeTxn(() async {
        await isar.tracks.put(track);
      });

      // Получаем свежую копию плейлиста из БД
      final freshPlaylist = await isar.playlists.get(playlist.id);
      if (freshPlaylist == null) {
        print('Playlist not found in database: ${playlist.name}');
        return;
      }

      // Создаем новый изменяемый список
      final trackIdsList = List<int>.from(freshPlaylist.trackIds);

      // Проверяем, что трек не добавлен уже в плейлист
      if (!trackIdsList.contains(track.id)) {
        trackIdsList.add(track.id);

        // Создаем новый плейлист с обновленным списком
        final updatedPlaylist = Playlist(
          id: freshPlaylist.id,
          name: freshPlaylist.name,
          coverImage: freshPlaylist.coverImage,
          trackIds: trackIdsList,
        );

        await isar.writeTxn(() async {
          await isar.playlists.put(updatedPlaylist);
        });

        // Обновляем локальный список плейлистов из БД
        _playlists = await isar.playlists.where().findAll();
        notifyListeners();

        print('Track ${track.title} added to playlist ${playlist.name}');
        print('Playlist now has ${trackIdsList.length} tracks');
      } else {
        print('Track ${track.title} is already in playlist ${playlist.name}');
      }
    } catch (e) {
      print('Error adding track to playlist: $e');
    }
  }

  Future<void> downloadTrack(Track track) async {
    if (track.localPath != null && await File(track.localPath!).exists()) {
      return; // already downloaded
    }

    final dio = Dio();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/${track.id}.mp3';
      final streamUrl = await _apiService.getStreamUrl(track.id);

      await dio.download(streamUrl, path);

      track.localPath = path;
      await isar.writeTxn(() async {
        await isar.tracks.put(track);
      });
      notifyListeners();
    } catch (e) {
      print('Error downloading track: $e');
    }
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    if (playlist.name != 'Favorites') {
      await isar.writeTxn(() async {
        await isar.playlists.delete(playlist.id);
      });

      // Обновляем локальный список плейлистов из БД
      _playlists = await isar.playlists.where().findAll();
      notifyListeners();

      print('Playlist deleted: ${playlist.name}');
    }
  }

  Future<void> removeTrackFromPlaylist(Track track, Playlist playlist) async {
    // Получаем свежую копию плейлиста из БД
    final freshPlaylist = await isar.playlists.get(playlist.id);
    if (freshPlaylist == null) {
      return;
    }

    // Создаем новый изменяемый список
    final trackIdsList = List<int>.from(freshPlaylist.trackIds);
    trackIdsList.remove(track.id);

    // Создаем новый плейлист с обновленным списком
    final updatedPlaylist = Playlist(
      id: freshPlaylist.id,
      name: freshPlaylist.name,
      coverImage: freshPlaylist.coverImage,
      trackIds: trackIdsList,
    );

    await isar.writeTxn(() async {
      await isar.playlists.put(updatedPlaylist);
    });

    // Обновляем локальный список плейлистов из БД
    _playlists = await isar.playlists.where().findAll();

    // Если это Favorites, обновляем stream
    if (playlist.name == 'Favorites') {
      _updateFavoritesStream();
    }

    notifyListeners();
  }

  Future<List<Track>> getTracksForPlaylist(Playlist playlist) async {
    try {
      // Получаем свежую копию плейлиста из БД
      final freshPlaylist = await isar.playlists.get(playlist.id);
      if (freshPlaylist == null) {
        print('Playlist not found: ${playlist.name}');
        return [];
      }

      print(
          'Getting tracks for playlist ${playlist.name}: ${freshPlaylist.trackIds.length} track IDs');

      final tracks = await isar.tracks.getAll(freshPlaylist.trackIds);
      final validTracks = tracks.whereType<Track>().toList();

      print('Found ${validTracks.length} valid tracks');
      return validTracks;
    } catch (e) {
      print('Error getting tracks for playlist: $e');
      return [];
    }
  }

  void pause() {
    _audioPlayer.pause();
  }

  void resume() {
    _audioPlayer.play();
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  void setVolume(double volume) {
    _audioPlayer.setVolume(volume);
  }

  // Метод для отладки - показать все плейлисты и их треки
  Future<void> debugPlaylists() async {
    final allPlaylists = await isar.playlists.where().findAll();
    for (final playlist in allPlaylists) {
      print('Playlist: ${playlist.name} (ID: ${playlist.id})');
      print('  Track IDs: ${playlist.trackIds}');
      final tracks = await getTracksForPlaylist(playlist);
      for (final track in tracks) {
        print('  - ${track.title} by ${track.artist}');
      }
    }
  }

  @override
  void dispose() {
    _favoritesController.close();
    _audioPlayer.dispose();
    super.dispose();
  }
}
