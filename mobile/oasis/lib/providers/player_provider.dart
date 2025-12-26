import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:oasis/models/playlist.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/services/api_service.dart';
import 'package:path_provider/path_provider.dart';

import '../services/audio_player_handler.dart';

class PlayerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AudioHandler _audioHandler;
  final Isar isar;

  Track? _currentTrack;
  List<Track> _currentPlaylist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  double _volume = 1.0;

  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  List<Playlist> _playlists = [];
  final List<Track> _recentTracks = [];

  final StreamController<List<int>> _favoritesController =
      StreamController<List<int>>.broadcast();

  Track? get currentTrack => _currentTrack;

  bool get isPlaying => _isPlaying;

  List<Playlist> get playlists =>
      _playlists.where((p) => p.name != 'History').toList();

  List<Track> get recentTracks => _recentTracks;

  Duration get totalDuration => _totalDuration;

  Duration get currentPosition => _currentPosition;

  double get volume => _volume;

  Stream<List<int>> get favoritesStream => _favoritesController.stream;

  Stream<Duration> get positionStream =>
      (_audioHandler as AudioPlayerHandler).onPositionChanged;

  Stream<Duration> get durationStream =>
      (_audioHandler as AudioPlayerHandler).onDurationChanged;

  Stream<Duration> get bufferedPositionStream => Stream.value(Duration.zero);

  Stream<double> get volumeStream => Stream.value(_volume);

  PlayerProvider({required this.isar, required AudioHandler audioHandler})
      : _audioHandler = audioHandler {
    _init();
  }

  void _init() {
    _loadPlaylists();

    final handler = _audioHandler as AudioPlayerHandler;

    handler.onNextCallback = playNext;
    handler.onPreviousCallback = playPrevious;

    handler.onPlayerStateChanged.listen((state) {
      final isPlaying = state == PlayerState.playing;
      if (_isPlaying != isPlaying) {
        _isPlaying = isPlaying;
        notifyListeners();
      }
    });

    handler.onDurationChanged.listen((d) {
      _totalDuration = d;
      notifyListeners();
    });

    handler.onPositionChanged.listen((p) {
      _currentPosition = p;
    });
  }

  Future<void> play(Track track, {List<Track>? playlist}) async {
    if (playlist != null) {
      _currentPlaylist = playlist;
    } else if (_currentPlaylist.isEmpty ||
        !_currentPlaylist.any((t) => t.id == track.id)) {
      _currentPlaylist = [track];
    }

    _currentIndex = _currentPlaylist.indexWhere((t) => t.id == track.id);

    if (_currentTrack?.id == track.id) {
      if (_isPlaying) {
        await _audioHandler.pause();
      } else {
        await _audioHandler.play();
      }
      return;
    }

    try {
      final handler = _audioHandler as AudioPlayerHandler;

      final mediaItem = MediaItem(
        id: track.id.toString(),
        album: track.artist,
        title: track.title,
        artist: track.artist,
        artUri: Uri.parse(track.albumCover),
        duration: null,
      );
      await handler.updateMediaItem(mediaItem);

      await _addToRecent(track);

      _currentTrack = track;
      notifyListeners();

      if (track.localPath != null && await File(track.localPath!).exists()) {
        await handler.setSourceDeviceFile(track.localPath!);
      } else {
        final streamUrl = await _apiService.getStreamUrl(track.id);
        await handler.setSourceUrl(streamUrl);
      }

      await _audioHandler.play();
      await handler.setVolume(_volume);
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
      _audioHandler.stop();
    }
  }

  void playPrevious() async {
    final position =
        await (_audioHandler as AudioPlayerHandler).getCurrentPosition();

    if (position.inSeconds > 3) {
      await _audioHandler.seek(Duration.zero);
      return;
    }

    if (_currentPlaylist.isNotEmpty && _currentIndex > 0) {
      _currentIndex--;
      play(_currentPlaylist[_currentIndex], playlist: _currentPlaylist);
    } else {
      await _audioHandler.seek(Duration.zero);
    }
  }

  void pause() => _audioHandler.pause();

  void resume() => _audioHandler.play();

  void seek(Duration position) => _audioHandler.seek(position);

  void setVolume(double v) {
    _volume = v;
    (_audioHandler as AudioPlayerHandler).setVolume(v);
    notifyListeners();
  }

  Future<void> _loadPlaylists() async {
    // 1. Сразу показываем локальные данные (мгновенный отклик)
    await _fetchLocalPlaylists();

    // 2. Фоном пробуем синхронизироваться с сервером
    _syncWithServer();
  }

  Future<void> _fetchLocalPlaylists() async {
    _playlists = await isar.playlists.where().findAll();

    // Создаем системные плейлисты локально, если их нет
    if (!_playlists.any((p) => p.name == 'History')) {
      final history = Playlist(name: 'History', trackIds: [], coverImage: '');
      await isar.writeTxn(() async => await isar.playlists.put(history));
      _playlists = await isar.playlists.where().findAll();
    }
    if (!_playlists.any((p) => p.name == 'Favorites')) {
      final favorites =
          Playlist(name: 'Favorites', trackIds: [], coverImage: '');
      await isar.writeTxn(() async => await isar.playlists.put(favorites));
      _playlists = await isar.playlists.where().findAll();
    }
    // (Favorites создается аналогично)

    notifyListeners();
  }

  Future<void> _syncWithServer() async {
    try {
      // А. Отправляем на сервер новые плейлисты, созданные офлайн
      final unsynced = await isar.playlists.filter().remoteIdIsNull().findAll();
      for (var p in unsynced) {
        if (p.name == 'History' || p.name == 'Favorites') continue;
        try {
          final newRemoteId = await _apiService.createPlaylist(p.name);
          p.remoteId = newRemoteId;
          await isar.writeTxn(() async => await isar.playlists.put(p));
          // TODO: Здесь можно было бы отправить и треки, если они были добавлены офлайн
        } catch (e) {
          print('Sync push error: $e');
        }
      }

      // Б. Скачиваем актуальное состояние с сервера
      final serverData = await _apiService.fetchPlaylistsRaw();

      await isar.writeTxn(() async {
        final serverIds = <int>[];

        for (final data in serverData) {
          final sId = data['id'] as int;
          serverIds.add(sId);

          // 1. Сохраняем треки в Isar (иначе ссылки на них будут битыми в офлайн)
          final List<int> trackIds = [];
          if (data['tracks'] != null) {
            for (final tJson in data['tracks']) {
              final track = Track.fromJson(tJson);
              await isar.tracks.put(track); // upsert
              trackIds.add(track.id);
            }
          }

          // 2. Обновляем или создаем плейлист в Isar
          final existing =
              await isar.playlists.filter().remoteIdEqualTo(sId).findFirst();

          if (existing != null) {
            existing.name = data['name'];
            existing.coverImage = data['cover_image'] ?? '';
            existing.trackIds = trackIds;
            await isar.playlists.put(existing);
          } else {
            final newPl = Playlist(
              remoteId: sId,
              name: data['name'],
              coverImage: data['cover_image'] ?? '',
              trackIds: trackIds,
            );
            await isar.playlists.put(newPl);
          }
        }

        // В. Удаляем локальные копии облачных плейлистов, если их удалили на сервере
        // (Оставляем только те, что remoteId == null, т.е. свежие офлайновые)
        await isar.playlists
            .filter()
            .remoteIdIsNotNull()
            .and()
            .not()
            .anyOf(serverIds, (q, id) => q.remoteIdEqualTo(id))
            .deleteAll();
      });

      // Обновляем UI
      await _fetchLocalPlaylists();
    } catch (e) {
      print("Sync failed (Offline mode): $e");
    }
  }

  Future<void> createPlaylist(String name) async {
    // 1. Создаем локально (Оптимистичный UI)
    final newPlaylist = Playlist(
      name: name,
      coverImage: '',
      trackIds: [],
      remoteId: null, // null = требует синхронизации
    );
    await isar.writeTxn(() async => await isar.playlists.put(newPlaylist));
    await _fetchLocalPlaylists();

    // 2. Пробуем отправить
    _syncWithServer();
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    if (playlist.name == 'Favorites' || playlist.name == 'History') return;
    await isar.writeTxn(() async => await isar.playlists.delete(playlist.id));
    await _fetchLocalPlaylists();

    if (playlist.remoteId != null) {
      try {
        await _apiService.deletePlaylist(playlist.remoteId!);
      } catch (_) {}
    }
  }

  Future<void> addTrackToPlaylist(Track track, Playlist playlist) async {
    // 1. Локально
    await isar.writeTxn(() async {
      await isar.tracks.put(track); // Гарантируем, что трек есть в базе
      final p = await isar.playlists.get(playlist.id);
      if (p != null) {
        final ids = List<int>.from(p.trackIds);
        if (!ids.contains(track.id)) {
          ids.add(track.id);
          p.trackIds = ids;
          await isar.playlists.put(p);
        }
      }
    });
    await _fetchLocalPlaylists();

    if (playlist.remoteId != null) {
      try {
        await _apiService.addTrackToPlaylist(playlist.remoteId!, track);
      } catch (e) {
        print('Queueing sync: $e');
      }
    }
  }

  Future<void> removeTrackFromPlaylist(Track track, Playlist playlist) async {
    // Аналогично addTrackToPlaylist: удаляем из Isar trackIds, потом шлем запрос на сервер
    // ... (код аналогичен addTrack, только remove и вызов API removeTrackFromPlaylist)
    await isar.writeTxn(() async {
      final p = await isar.playlists.get(playlist.id);
      if (p != null) {
        final ids = List<int>.from(p.trackIds);
        ids.remove(track.id);
        p.trackIds = ids;
        await isar.playlists.put(p);
      }
    });
    await _fetchLocalPlaylists();

    if (playlist.remoteId != null) {
      try {
        await _apiService.removeTrackFromPlaylist(playlist.remoteId!, track.id);
      } catch (_) {}
    }
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

  Future<void> _addToRecent(Track track) async {
    _recentTracks.removeWhere((t) => t.id == track.id);
    _recentTracks.insert(0, track);
    if (_recentTracks.length > 15) _recentTracks.removeLast();

    notifyListeners();

    try {
      await isar.writeTxn(() async => await isar.tracks.put(track));

      final historyPlaylist = _playlists.firstWhere((p) => p.name == 'History',
          orElse: () => Playlist(
              id: Isar.autoIncrement,
              name: 'History',
              trackIds: [],
              coverImage: ''));

      final newIds = _recentTracks.map((t) => t.id).toList();

      final updated = Playlist(
        id: historyPlaylist.id,
        name: historyPlaylist.name,
        coverImage: historyPlaylist.coverImage,
        trackIds: newIds,
      );

      await isar.writeTxn(() async => await isar.playlists.put(updated));

      final index = _playlists.indexWhere((p) => p.name == 'History');
      if (index != -1) {
        _playlists[index] = updated;
      } else {
        _playlists.add(updated);
      }
    } catch (e) {
      print("Error saving history: $e");
    }
  }

  @override
  void dispose() {
    _favoritesController.close();
    super.dispose();
  }

  Future<void> clearHistory() async {
    final historyPlaylist =
        await isar.playlists.filter().nameEqualTo('History').findFirst();

    if (historyPlaylist != null) {
      await isar.writeTxn(() async {
        historyPlaylist.trackIds = [];
        await isar.playlists.put(historyPlaylist);
      });

      _recentTracks.clear();
      notifyListeners();
    }
  }

  Future<void> downloadTrack(Track track) async {
    // Если путь уже есть и файл существует - выходим
    if (track.localPath != null && await File(track.localPath!).exists())
      return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/${track.id}.mp3';

      // Используем внешний сервис или тот же, если он внутри
      final streamUrl = await _apiService.getStreamUrl(track.id);
      await Dio().download(streamUrl, path);

      // 1. Обновляем переданный объект
      track.localPath = path;

      // 2. Обновляем базу
      await isar.writeTxn(() async => await isar.tracks.put(track));

      // 3. ФИКС: Если скачанный трек сейчас играет, обновляем и _currentTrack
      if (_currentTrack != null && _currentTrack!.id == track.id) {
        _currentTrack!.localPath = path;
      }

      notifyListeners();
    } catch (e) {
      print("Download error: $e");
    }
  }

  Future<void> removeDownload(Track track) async {
    if (track.localPath != null) {
      final file = File(track.localPath!);
      if (await file.exists()) {
        await file.delete();
      }

      track.localPath = null;
      await isar.writeTxn(() async => await isar.tracks.put(track));

      // 3. ФИКС: Если удаляемый трек сейчас играет, обновляем и _currentTrack
      if (_currentTrack != null && _currentTrack!.id == track.id) {
        _currentTrack!.localPath = null;
      }

      notifyListeners();
    }
  }

  Future<void> clearAllDownloads() async {
    final downloadedTracks =
        await isar.tracks.filter().localPathIsNotNull().findAll();

    await isar.writeTxn(() async {
      for (var track in downloadedTracks) {
        if (track.localPath != null) {
          final file = File(track.localPath!);
          if (await file.exists()) {
            await file.delete();
          }
          track.localPath = null;
          await isar.tracks.put(track);

          // ФИКС: Проверяем текущий трек в цикле
          if (_currentTrack != null && _currentTrack!.id == track.id) {
            _currentTrack!.localPath = null;
          }
        }
      }
    });

    notifyListeners();
  }
}
