import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:oasis/models/playlist.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/services/api_service.dart';
import 'package:path_provider/path_provider.dart';

class PlayerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Isar isar;

  // --- Состояние плеера ---
  Track? _currentTrack;
  List<Track> _currentPlaylist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  double _volume = 1.0;

  // Кешированные данные для UI (чтобы не было нулей при открытии плеера)
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  // Плейлисты и история
  List<Playlist> _playlists = [];
  final List<Track> _recentTracks = [];

  // Контроллер для стрима избранного
  final StreamController<List<int>> _favoritesController =
      StreamController<List<int>>.broadcast();

  // --- Геттеры ---
  Track? get currentTrack => _currentTrack;

  bool get isPlaying => _isPlaying;

  List<Playlist> get playlists => _playlists;

  List<Track> get recentTracks => _recentTracks;

  AudioPlayer get audioPlayer => _audioPlayer;

  // Геттеры данных для UI
  Duration get totalDuration => _totalDuration;

  Duration get currentPosition => _currentPosition;

  double get volume => _volume;

  // Потоки
  Stream<List<int>> get favoritesStream => _favoritesController.stream;

  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;

  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;

  // Заглушка для буферизации (в audioplayers её нет в явном виде)
  Stream<Duration> get bufferedPositionStream => Stream.value(Duration.zero);

  // Заглушка для громкости (используем локальное состояние _volume)
  Stream<double> get volumeStream => Stream.value(_volume);

  PlayerProvider({required this.isar}) {
    _init();
  }

  void _init() {
    _loadPlaylists();

    // 1. Слушаем состояние (Play/Pause)
    _audioPlayer.onPlayerStateChanged.listen((state) {
      final isPlaying = state == PlayerState.playing;
      if (_isPlaying != isPlaying) {
        _isPlaying = isPlaying;
        notifyListeners();
      }
    });

    // 2. Слушаем окончание трека (Авто-переключение)
    _audioPlayer.onPlayerComplete.listen((_) {
      playNext();
    });

    // 3. Кешируем длительность для UI
    _audioPlayer.onDurationChanged.listen((d) {
      _totalDuration = d;
      notifyListeners();
    });

    // 4. Кешируем позицию для UI
    _audioPlayer.onPositionChanged.listen((p) {
      _currentPosition = p;
    });
  }

  // --- Основная логика воспроизведения ---

  Future<void> play(Track track, {List<Track>? playlist}) async {
    // 1. Управление очередью
    if (playlist != null) {
      _currentPlaylist = playlist;
    } else if (_currentPlaylist.isEmpty ||
        !_currentPlaylist.any((t) => t.id == track.id)) {
      _currentPlaylist = [track];
    }

    _currentIndex = _currentPlaylist.indexWhere((t) => t.id == track.id);

    // 2. Если трек тот же самый - Пауза/Старт
    if (_currentTrack?.id == track.id) {
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
      return;
    }

    try {
      // 3. Запуск нового трека
      await _audioPlayer.stop(); // Останавливаем предыдущий

      // Сброс UI
      _totalDuration = Duration.zero;
      _currentPosition = Duration.zero;

      _addToRecent(track);
      _currentTrack = track;
      notifyListeners();

      // Выбор источника (файл или сеть)
      Source source;
      if (track.localPath != null && await File(track.localPath!).exists()) {
        source = DeviceFileSource(track.localPath!);
      } else {
        final streamUrl = await _apiService.getStreamUrl(track.id);
        source = UrlSource(streamUrl);
      }

      await _audioPlayer.play(source);
      await _audioPlayer.setVolume(_volume); // Применяем громкость
    } catch (e) {
      print('Error playing track: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  void playNext() {
    if (_currentPlaylist.isNotEmpty &&
        _currentIndex < _currentPlaylist.length - 1) {
      _currentIndex++;
      play(_currentPlaylist[_currentIndex], playlist: _currentPlaylist);
    } else {
      _audioPlayer.stop();
    }
  }

  void playPrevious() async {
    // Если трек играет > 3 сек, возвращаемся в начало
    final position = await _audioPlayer.getCurrentPosition();
    if (position != null && position.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
      return;
    }

    // Иначе предыдущий трек
    if (_currentPlaylist.isNotEmpty && _currentIndex > 0) {
      _currentIndex--;
      play(_currentPlaylist[_currentIndex], playlist: _currentPlaylist);
    } else {
      await _audioPlayer.seek(Duration.zero);
    }
  }

  void pause() => _audioPlayer.pause();

  void resume() => _audioPlayer.resume();

  void seek(Duration position) => _audioPlayer.seek(position);

  void setVolume(double v) {
    _volume = v;
    _audioPlayer.setVolume(v);
    notifyListeners();
  }

  // --- Логика плейлистов и БД ---

  Future<void> _loadPlaylists() async {
    _playlists = await isar.playlists.where().findAll();
    // Создаем Favorites если нет
    if (!_playlists.any((p) => p.name == 'Favorites')) {
      final favorites = Playlist(
          id: Isar.autoIncrement,
          name: 'Favorites',
          trackIds: [],
          coverImage: '');
      await isar.writeTxn(() async => await isar.playlists.put(favorites));
      _playlists = await isar.playlists.where().findAll();
    }
    _updateFavoritesStream();
    notifyListeners();
  }

  void _updateFavoritesStream() {
    try {
      final fav = _playlists.firstWhere((p) => p.name == 'Favorites');
      _favoritesController.add(fav.trackIds);
    } catch (_) {}
  }

  Future<void> createPlaylist(String name) async {
    final newPlaylist = Playlist(
        id: Isar.autoIncrement, name: name, trackIds: [], coverImage: '');
    await isar.writeTxn(() async => await isar.playlists.put(newPlaylist));
    await _loadPlaylists();
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    if (playlist.name == 'Favorites') return;
    await isar.writeTxn(() async => await isar.playlists.delete(playlist.id));
    await _loadPlaylists();
  }

  Future<void> addTrackToPlaylist(Track track, Playlist playlist) async {
    await isar.writeTxn(() async => await isar.tracks.put(track));
    final p = await isar.playlists.get(playlist.id);
    if (p == null) return;
    final ids = List<int>.from(p.trackIds);
    if (!ids.contains(track.id)) {
      ids.add(track.id);
      final updated = Playlist(
          id: p.id, name: p.name, coverImage: p.coverImage, trackIds: ids);
      await isar.writeTxn(() async => await isar.playlists.put(updated));
      await _loadPlaylists();
    }
  }

  Future<void> removeTrackFromPlaylist(Track track, Playlist playlist) async {
    final p = await isar.playlists.get(playlist.id);
    if (p == null) return;
    final ids = List<int>.from(p.trackIds);
    ids.remove(track.id);
    final updated = Playlist(
        id: p.id, name: p.name, coverImage: p.coverImage, trackIds: ids);
    await isar.writeTxn(() async => await isar.playlists.put(updated));
    await _loadPlaylists();
  }

  Future<void> toggleFavorite(Track track) async {
    await isar.writeTxn(() async => await isar.tracks.put(track));
    final fav = _playlists.firstWhere((p) => p.name == 'Favorites');
    final ids = List<int>.from(fav.trackIds);
    if (ids.contains(track.id)) {
      ids.remove(track.id);
    } else {
      ids.add(track.id);
    }
    final updated = Playlist(
        id: fav.id, name: fav.name, coverImage: fav.coverImage, trackIds: ids);
    await isar.writeTxn(() async => await isar.playlists.put(updated));
    await _loadPlaylists();
  }

  Future<bool> isFavorite(Track track) async {
    try {
      final fav = _playlists.firstWhere((p) => p.name == 'Favorites');
      return fav.trackIds.contains(track.id);
    } catch (_) {
      return false;
    }
  }

  Future<List<Track>> getTracksForPlaylist(Playlist playlist) async {
    final fresh = await isar.playlists.get(playlist.id);
    if (fresh == null) return [];
    final tracks = await isar.tracks.getAll(fresh.trackIds);
    return tracks.whereType<Track>().toList();
  }

  Future<void> downloadTrack(Track track) async {
    if (track.localPath != null && await File(track.localPath!).exists())
      return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/${track.id}.mp3';
      final streamUrl = await _apiService.getStreamUrl(track.id);
      await Dio().download(streamUrl, path);
      track.localPath = path;
      await isar.writeTxn(() async => await isar.tracks.put(track));
      notifyListeners();
    } catch (e) {
      print("Download error: $e");
    }
  }

  void _addToRecent(Track track) {
    _recentTracks.removeWhere((t) => t.id == track.id);
    _recentTracks.insert(0, track);
    if (_recentTracks.length > 15) _recentTracks.removeLast();
  }

  @override
  void dispose() {
    _favoritesController.close();
    _audioPlayer.dispose();
    super.dispose();
  }
}
