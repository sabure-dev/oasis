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

  List<Playlist> get playlists => _playlists.where((p) => p.name != 'History').toList();

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

    handler.onPlayerComplete.listen((_) {
      playNext();
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
    _playlists = await isar.playlists.where().findAll();

    if (!_playlists.any((p) => p.name == 'Favorites')) {
      final favorites = Playlist(
          id: Isar.autoIncrement,
          name: 'Favorites',
          trackIds: [],
          coverImage: '');
      await isar.writeTxn(() async => await isar.playlists.put(favorites));
      _playlists = await isar.playlists.where().findAll();
    }

    Playlist? historyPlaylist;
    try {
      historyPlaylist = _playlists.firstWhere((p) => p.name == 'History');
    } catch (_) {
      historyPlaylist = Playlist(
          id: Isar.autoIncrement,
          name: 'History',
          trackIds: [],
          coverImage: '');
      await isar.writeTxn(() async => await isar.playlists.put(historyPlaylist!));
      _playlists = await isar.playlists.where().findAll();
    }

    if (historyPlaylist.trackIds.isNotEmpty) {
      final tracks = await isar.tracks.getAll(historyPlaylist.trackIds);
      _recentTracks.clear();
      _recentTracks.addAll(tracks.whereType<Track>().toList());
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
    if (playlist.name == 'Favorites' || playlist.name == 'History') return;
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

  Future<void> _addToRecent(Track track) async {
    _recentTracks.removeWhere((t) => t.id == track.id);
    _recentTracks.insert(0, track);
    if (_recentTracks.length > 15) _recentTracks.removeLast();

    notifyListeners();

    try {
      await isar.writeTxn(() async => await isar.tracks.put(track));

      final historyPlaylist = _playlists.firstWhere(
        (p) => p.name == 'History',
        orElse: () => Playlist(id: Isar.autoIncrement, name: 'History', trackIds: [], coverImage: '')
      );

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
}