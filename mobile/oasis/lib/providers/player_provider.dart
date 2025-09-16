import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:oasis/models/playlist.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/services/api_service.dart';

class PlayerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Track? _currentTrack;
  List<Track> _currentPlaylist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;

  final Playlist _favoritesPlaylist = Playlist(name: 'Favorites', tracks: []);

  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Playlist get favoritesPlaylist => _favoritesPlaylist;
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
      final streamUrl = await _apiService.getStreamUrl(track.id);
      await _audioPlayer.setUrl(streamUrl);
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
    }
  }

  void toggleFavorite(Track track) {
    final isFav = isFavorite(track);
    if (isFav) {
      _favoritesPlaylist.tracks.removeWhere((t) => t.id == track.id);
    } else {
      _favoritesPlaylist.tracks.add(track);
    }
    notifyListeners();
  }

  bool isFavorite(Track track) {
    return _favoritesPlaylist.tracks.any((t) => t.id == track.id);
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