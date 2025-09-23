import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:oasis/models/playlist.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/services/api_service.dart';
import 'package:path_provider/path_provider.dart';

class PlayerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Track? _currentTrack;
  List<Track> _currentPlaylist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;

  final List<Playlist> _playlists = [Playlist(name: 'Favorites', tracks: [])];

  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  List<Playlist> get playlists => _playlists;
  AudioPlayer get audioPlayer => _audioPlayer;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration> get bufferedPositionStream =>
      _audioPlayer.bufferedPositionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<double> get volumeStream => _audioPlayer.volumeStream;

  PlayerProvider() {
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }

  Future<void> play(Track track, {List<Track>? playlist}) async {
    _currentPlaylist = playlist ?? [track];
    _currentIndex = _currentPlaylist.indexWhere((t) => t.id == track.id);

    if (_currentTrack?.id == track.id && _isPlaying) {
      return;
    }

    try {
      if (track.localPath != null && await File(track.localPath!).exists()) {
        await _audioPlayer.setFilePath(track.localPath!);
      } else {
        final streamUrl = await _apiService.getStreamUrl(track.id);
        await _audioPlayer.setUrl(streamUrl);
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
      // Handle error
    }
  }

  void playNext() {
    if (_currentPlaylist.isNotEmpty && _currentIndex < _currentPlaylist.length - 1) {
      _currentIndex++;
      play(_currentPlaylist[_currentIndex], playlist: _currentPlaylist);
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }

  void toggleFavorite(Track track) {
    final favoritesPlaylist = _playlists.first;
    final isFav = isFavorite(track);
    if (isFav) {
      favoritesPlaylist.tracks.removeWhere((t) => t.id == track.id);
    } else {
      favoritesPlaylist.tracks.add(track);
    }
    notifyListeners();
  }

  bool isFavorite(Track track) {
    return _playlists.first.tracks.any((t) => t.id == track.id);
  }

  void createPlaylist(String name) {
    _playlists.add(Playlist(name: name, tracks: []));
    notifyListeners();
  }

  void addTrackToPlaylist(Track track, Playlist playlist) {
    // ensures the track is not already in the playlist to avoid duplicates
    if (!playlist.tracks.any((t) => t.id == track.id)) {
      playlist.tracks.add(track);
      notifyListeners();
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
      notifyListeners();
    } catch (e) {
      // handle download error
    }
  }

  void deletePlaylist(Playlist playlist) {
    if (playlist.name != 'Favorites') { // prevent deleting the Favorites playlist
      _playlists.removeWhere((p) => p.name == playlist.name);
      notifyListeners();
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
}