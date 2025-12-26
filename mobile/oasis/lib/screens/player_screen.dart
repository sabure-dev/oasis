import 'package:flutter/material.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/providers/theme_provider.dart';
import 'package:oasis/widgets/glass_card.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

// --- МИНИ-ПЛЕЕР ---
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        if (playerProvider.currentTrack == null) {
          return const SizedBox.shrink();
        }

        final track = playerProvider.currentTrack!;

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _FullScreenPlayer(),
              fullscreenDialog: true,
            ),
          ),
          child: GlassCard(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.0),
                        child: Image.network(
                          track.albumCover,
                          width: 45,
                          height: 45,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            width: 45,
                            height: 45,
                            child: const Icon(Icons.music_note,
                                color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              track.artist,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FavoriteButton(track: track),
                          IconButton(
                            icon: Icon(
                              playerProvider.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () => playerProvider.isPlaying
                                ? playerProvider.pause()
                                : playerProvider.resume(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _MiniProgressBar(playerProvider: playerProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- ПОЛНОЭКРАННЫЙ ПЛЕЕР ---
class _FullScreenPlayer extends StatelessWidget {
  const _FullScreenPlayer();

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, ThemeProvider>(
      builder: (context, player, theme, child) {
        final track = player.currentTrack;
        if (track == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context);
          });
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              _DynamicBackground(
                imageUrl: track.albumCover,
                fallbackColor: theme.currentTheme.startColor,
              ),
              SafeArea(
                child: Column(
                  children: [
                    // Кнопка закрытия
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // Обложка
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size =
                                constraints.maxWidth < constraints.maxHeight
                                    ? constraints.maxWidth
                                    : constraints.maxHeight;

                            return Center(
                              child: SizedBox(
                                width: size,
                                height: size,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    track.albumCover,
                                    fit: BoxFit.cover,
                                    width: size,
                                    height: size,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: size,
                                        height: size,
                                        decoration: BoxDecoration(
                                          color: Colors.white10,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Icon(Icons.music_note,
                                            color: Colors.white54, size: 80),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Инфо
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          Text(
                            track.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            track.artist,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 18),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Слайдер прогресса
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: StreamBuilder<Duration>(
                        stream: player.positionStream,
                        initialData: player.currentPosition,
                        builder: (context, snapshot) {
                          final pos = snapshot.data ?? Duration.zero;

                          return StreamBuilder<Duration>(
                              stream: player.durationStream,
                              initialData: player.totalDuration,
                              builder: (context, durationSnap) {
                                final dur = durationSnap.data ?? Duration.zero;
                                final max = dur.inMilliseconds > 0
                                    ? dur.inMilliseconds.toDouble()
                                    : 1.0;
                                final value = pos.inMilliseconds
                                    .clamp(0, max.toInt())
                                    .toDouble();

                                return Column(
                                  children: [
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        thumbShape: const RoundSliderThumbShape(
                                            enabledThumbRadius: 6),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                                overlayRadius: 14),
                                        trackHeight: 4,
                                        activeTrackColor: Colors.white,
                                        inactiveTrackColor: Colors.white24,
                                        thumbColor: Colors.white,
                                      ),
                                      child: Slider(
                                        min: 0.0,
                                        max: max,
                                        value: value,
                                        onChanged: (v) {
                                          player.seek(Duration(
                                              milliseconds: v.round()));
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_formatDuration(pos),
                                              style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12)),
                                          Text(_formatDuration(dur),
                                              style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Кнопки управления
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.playlist_add,
                              color: Colors.white70, size: 28),
                          onPressed: () =>
                              _showAddToPlaylistDialog(context, track),
                        ),
                        IconButton(
                          iconSize: 42,
                          icon: const Icon(Icons.skip_previous,
                              color: Colors.white),
                          onPressed: player.playPrevious,
                        ),
                        Container(
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(12),
                          child: InkWell(
                            onTap: () => player.isPlaying
                                ? player.pause()
                                : player.resume(),
                            child: Icon(
                              player.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.black,
                              size: 36,
                            ),
                          ),
                        ),
                        IconButton(
                          iconSize: 42,
                          icon:
                              const Icon(Icons.skip_next, color: Colors.white),
                          onPressed: player.playNext,
                        ),
                        _FavoriteButton(track: track, size: 28),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Доп. кнопки
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // [FIX 3] ИСПРАВЛЕННАЯ ЛОГИКА СКАЧИВАНИЯ
                          IconButton(
                            icon: Icon(
                              track.localPath != null
                                  ? Icons.download_done_rounded
                                  : Icons.download_rounded,
                              // Делаем иконку яркой, если скачано
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              if (track.localPath != null) {
                                // Если уже есть - удаляем
                                player.removeDownload(track);
                              } else {
                                // Если нет - качаем
                                player.downloadTrack(track);
                              }
                            },
                          ),
                          _VolumeControl(playerProvider: player),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, Track track) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final availablePlaylists =
        playerProvider.playlists.where((p) => p.name != 'Favorites').toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add to Playlist',
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: availablePlaylists.isEmpty
              ? const Text("No playlists created yet",
                  style: TextStyle(color: Colors.white70))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availablePlaylists.length,
                  itemBuilder: (context, index) {
                    final playlist = availablePlaylists[index];
                    return ListTile(
                      title: Text(playlist.name,
                          style: const TextStyle(color: Colors.white)),
                      leading:
                          const Icon(Icons.queue_music, color: Colors.white70),
                      onTap: () {
                        playerProvider.addTrackToPlaylist(track, playlist);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${playlist.name}')),
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

// ... (Остальные виджеты: _DynamicBackground, _MiniProgressBar, _FavoriteButton, _VolumeControl без изменений, они были правильными)
// Оставьте их как в вашем коде
class _DynamicBackground extends StatefulWidget {
  final String imageUrl;
  final Color fallbackColor;

  const _DynamicBackground({
    required this.imageUrl,
    required this.fallbackColor,
  });

  @override
  State<_DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<_DynamicBackground> {
  Color? dominantColor;

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  @override
  void didUpdateWidget(covariant _DynamicBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _updatePalette();
    }
  }

  Future<void> _updatePalette() async {
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(widget.imageUrl),
        maximumColorCount: 20,
      );
      if (mounted) {
        setState(() {
          dominantColor = paletteGenerator.dominantColor?.color;
        });
      }
    } catch (e) {
      // Игнорируем ошибки палитры
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = dominantColor ?? widget.fallbackColor;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  final PlayerProvider playerProvider;

  const _MiniProgressBar({required this.playerProvider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: playerProvider.positionStream,
      initialData: playerProvider.currentPosition,
      builder: (context, snapshot) {
        final pos = snapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
            stream: playerProvider.durationStream,
            initialData: playerProvider.totalDuration,
            builder: (context, durationSnap) {
              final dur = durationSnap.data ?? Duration.zero;
              final max =
                  dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
              final value = pos.inMilliseconds.clamp(0, max.toInt()).toDouble();

              // Используем Slider вместо LinearProgressIndicator
              return SizedBox(
                height: 20, // Чуть больше высоты для удобства нажатия
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    // Тонкая линия как раньше
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 0),
                    // Скрываем "шарик" (или поставьте 4.0, если нужен)
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 10),
                    // Зона нажатия
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    // Убираем стандартные отступы слайдера по краям
                    trackShape: const RectangularSliderTrackShape(),
                  ),
                  child: Slider(
                    value: value,
                    min: 0.0,
                    max: max,
                    onChanged: (v) {
                      playerProvider.seek(Duration(milliseconds: v.round()));
                    },
                  ),
                ),
              );
            });
      },
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final Track track;
  final double size;

  const _FavoriteButton({required this.track, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    // [FIX 2] Получаем начальное состояние из списка плейлистов
    List<int> getInitialFavorites() {
      try {
        final fav =
            playerProvider.playlists.firstWhere((p) => p.name == 'Favorites');
        return fav.trackIds;
      } catch (_) {
        return [];
      }
    }

    return StreamBuilder<List<int>>(
      stream: playerProvider.favoritesStream,
      initialData: getInitialFavorites(), // <-- Исправление "не горящей" иконки
      builder: (context, snapshot) {
        final isFav = (snapshot.data ?? []).contains(track.id);

        return IconButton(
          iconSize: size,
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.red : Colors.white70,
          ),
          onPressed: () => playerProvider.toggleFavorite(track),
        );
      },
    );
  }
}

class _VolumeControl extends StatefulWidget {
  final PlayerProvider playerProvider;

  const _VolumeControl({required this.playerProvider});

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    // Получаем позицию кнопки, чтобы знать где рисовать
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Прозрачный слой на весь экран для закрытия при клике мимо
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Сам слайдер
          Positioned(
            width: 50,
            height: 160,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              // Сдвигаем вверх на (высота слайдера + отступ) и центрируем по X
              offset: Offset(0, -170),
              child: Material(
                elevation: 4.0,
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      const Icon(Icons.volume_up,
                          color: Colors.white, size: 18),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Consumer<PlayerProvider>(
                            builder: (context, player, _) {
                              return SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 16),
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: player.volume,
                                  onChanged: (v) => player.setVolume(v),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Icon(Icons.volume_mute,
                          color: Colors.white54, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // CompositedTransformTarget нужен для привязки Overlay к этому виджету
    return CompositedTransformTarget(
      link: _layerLink,
      child: IconButton(
        icon: const Icon(Icons.volume_up, color: Colors.white70),
        onPressed: () {
          if (_overlayEntry == null) {
            _showOverlay();
          } else {
            _removeOverlay();
          }
        },
      ),
    );
  }
}
