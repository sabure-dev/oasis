import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/services/api_service.dart';

class PlayerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Track? _currentTrack;
  bool _isPlaying = false;

  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  AudioPlayer get audioPlayer => _audioPlayer;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration> get bufferedPositionStream => _audioPlayer.bufferedPositionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<double> get volumeStream => _audioPlayer.volumeStream;

  Future<void> play(Track track) async {
    if (_currentTrack?.id == track.id) {
      _audioPlayer.play();
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