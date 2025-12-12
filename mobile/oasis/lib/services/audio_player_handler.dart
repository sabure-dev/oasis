import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();

  // Колбэки для переключения треков (свяжем их с Provider)
  Function()? onNextCallback;
  Function()? onPreviousCallback;

  AudioPlayerHandler() {
    // Слушаем состояние плеера
    _player.onPlayerStateChanged.listen((state) {
      _broadcastState();
    });

    // Слушаем позицию (передаем её в broadcast, чтобы обновить шторку)
    _player.onPositionChanged.listen((position) {
      _broadcastState(position: position);
    });

    // Слушаем длительность
    _player.onDurationChanged.listen((duration) {
      final oldItem = mediaItem.value;
      if (oldItem != null) {
        mediaItem.add(oldItem.copyWith(duration: duration));
      }
    });

    // Слушаем окончание трека
    _player.onPlayerComplete.listen((_) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.completed,
      ));
      if (onNextCallback != null) onNextCallback!();
    });
  }

  /// Обновляет состояние воспроизведения в системе (шторка)
  Future<void> _broadcastState({Duration? position}) async {
    // Если позиция не пришла из стрима, пытаемся получить текущую
    final currentPos =
        position ?? await _player.getCurrentPosition() ?? Duration.zero;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.state == PlayerState.playing)
          MediaControl.pause
        else
          MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        PlayerState.stopped: AudioProcessingState.idle,
        PlayerState.playing: AudioProcessingState.ready,
        PlayerState.paused: AudioProcessingState.ready,
        PlayerState.completed: AudioProcessingState.completed,
        PlayerState.disposed: AudioProcessingState.idle,
      }[_player.state]!,
      playing: _player.state == PlayerState.playing,
      updatePosition: currentPos,
      bufferedPosition: Duration.zero,
      speed: 1.0,
      queueIndex: 0,
    ));
  }

  // --- Override методов управления (из шторки) ---

  @override
  Future<void> play() => _player.resume();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (onNextCallback != null) onNextCallback!();
  }

  @override
  Future<void> skipToPrevious() async {
    if (onPreviousCallback != null) onPreviousCallback!();
  }

  @override
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  // --- Внутренние методы (вызываются из Provider) ---

  Future<void> setSourceUrl(String url) async {
    await _player.setSourceUrl(url);
  }

  Future<void> setSourceDeviceFile(String path) async {
    await _player.setSourceDeviceFile(path);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  /// Метод для получения текущей позиции (нужен в Provider)
  Future<Duration> getCurrentPosition() async {
    return await _player.getCurrentPosition() ?? Duration.zero;
  }

  // Пробрасываем стримы для UI
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;

  Stream<Duration> get onDurationChanged => _player.onDurationChanged;

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  Stream<void> get onPlayerComplete => _player.onPlayerComplete;
}
