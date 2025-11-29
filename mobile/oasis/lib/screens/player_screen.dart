import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/widgets/glass_card.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        if (playerProvider.currentTrack == null) {
          return const SizedBox.shrink();
        }

        final track = playerProvider.currentTrack!;

        return GestureDetector(
          onTap: () => _openFullScreenPlayer(context, track, playerProvider),
          child: GlassCard(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Основная строка с информацией и кнопками
                  _buildMainRow(track, playerProvider, context),

                  const SizedBox(height: 8),

                  // Прогресс-бар
                  _buildProgressSection(playerProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openFullScreenPlayer(
      BuildContext context, Track track, PlayerProvider playerProvider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenPlayer(track: track),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildMainRow(
      Track track, PlayerProvider playerProvider, BuildContext context) {
    // Определяем, является ли это десктопной версией
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Row(
      children: [
        // Обложка альбома (меньший размер)
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.0),
            child: Image.network(
              track.albumCover,
              width: 45,
              height: 45,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: const Icon(Icons.music_note,
                      color: Colors.white54, size: 20),
                );
              },
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Информация о треке
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                track.artist,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),

        // Кнопки управления
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Громкость (только на десктопе)
            if (isDesktop) _VolumeControl(playerProvider: playerProvider),

            // Кнопка избранного
            FutureBuilder<bool>(
              future: playerProvider.isFavorite(track),
              builder: (context, snapshot) {
                final isFavorite = snapshot.data ?? false;
                return StreamBuilder<List<int>>(
                  stream: playerProvider.favoritesStream,
                  initialData: playerProvider.playlists
                      .firstWhere((p) => p.name == 'Favorites')
                      .trackIds,
                  builder: (context, streamSnapshot) {
                    final currentIsFavorite =
                        streamSnapshot.data?.contains(track.id) ?? isFavorite;
                    return IconButton(
                      padding: const EdgeInsets.all(8),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () async {
                        await playerProvider.toggleFavorite(track);
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          currentIsFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          key: ValueKey(currentIsFavorite),
                          color:
                              currentIsFavorite ? Colors.red : Colors.white70,
                          size: 20,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(width: 4),

            // Играть/Пауза
            IconButton(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                if (playerProvider.isPlaying) {
                  playerProvider.pause();
                } else {
                  playerProvider.resume();
                }
              },
              icon: Icon(
                playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSection(PlayerProvider playerProvider) {
    return StreamBuilder<Duration>(
      stream: playerProvider.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: playerProvider.durationStream,
          builder: (context, snapshot) {
            final duration = snapshot.data ?? Duration.zero;
            final progress = duration.inMilliseconds > 0
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0;

            return Column(
              children: [
                // Прогресс-бар
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white24,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (value) {
                      final newPosition = Duration(
                        milliseconds: (value * duration.inMilliseconds).round(),
                      );
                      playerProvider.seek(newPosition);
                    },
                  ),
                ),

                // Время
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLarge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLarge ? Colors.white24 : Colors.transparent,
      ),
      child: IconButton(
        iconSize: isLarge ? 36 : 24,
        icon: Icon(
          icon,
          color: onPressed != null ? Colors.white : Colors.white38,
        ),
        onPressed: onPressed,
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, Track track) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final availablePlaylists =
        playerProvider.playlists.where((p) => p.name != 'Favorites').toList();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add to Playlist',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availablePlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = availablePlaylists[index];
                      return InkWell(
                        onTap: () {
                          playerProvider.addTrackToPlaylist(track, playlist);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Added ${track.title} to ${playlist.name}'),
                              backgroundColor: const Color(0xFF65A6F3),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.queue_music,
                                  color: Colors.black.withValues(alpha: 0.6),
                                  size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  playlist.name,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Icon(Icons.add,
                                  color: Colors.black.withValues(alpha: 0.4),
                                  size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FullScreenPlayer extends StatefulWidget {
  final Track track;

  const _FullScreenPlayer({required this.track});

  @override
  State<_FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<_FullScreenPlayer> {
  Color startColor = Colors.black;
  Color endColor = Colors.black87;

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      NetworkImage(widget.track.albumCover),
      size: const Size(200, 200),
      maximumColorCount: 20,
    );

    setState(() {
      startColor = paletteGenerator.dominantColor?.color ?? Colors.black;
      // Если есть тёмный вариант, используем его, иначе берём немного затемнённый доминирующий
      endColor =
          paletteGenerator.darkMutedColor?.color ?? startColor.withOpacity(0.8);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, ThemeProvider>(
      builder: (context, playerProvider, themeProvider, child) {
        final themeBackground = LinearGradient(
          colors: [
            themeProvider.currentTheme.startColor,
            themeProvider.currentTheme.endColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

        return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(children: [
              Positioned.fill(
                child: widget.track.albumCover.isNotEmpty
                    ? Image.network(
                        widget.track.albumCover,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration:
                                BoxDecoration(gradient: themeBackground),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(gradient: themeBackground),
                      ),
              ),

              // 🔹 Размытие и затемнение
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ),

              // 🔹 Основной контент поверх
              SafeArea(
                child: Column(
                  children: [
                    // Верхняя панель
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white, size: 32),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Обложка
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.track.albumCover,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            // или фиксированный размер, например 300
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: double.infinity, // <- ключевой момент
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.music_note,
                                    color: Colors.white54, size: 80),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Название трека и артист
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Text(
                            widget.track.title,
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
                            widget.track.artist,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),
                    // Прогресс
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: StreamBuilder<Duration>(
                        stream: playerProvider.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          return StreamBuilder<Duration?>(
                            stream: playerProvider.durationStream,
                            builder: (context, snapshot) {
                              final duration = snapshot.data ?? Duration.zero;
                              final progress = duration.inMilliseconds > 0
                                  ? position.inMilliseconds /
                                      duration.inMilliseconds
                                  : 0.0;

                              return Column(
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 8),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                              overlayRadius: 20),
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.white24,
                                      thumbColor: Colors.white,
                                      overlayColor: Colors.white24,
                                    ),
                                    child: Slider(
                                      value: progress.clamp(0.0, 1.0),
                                      onChanged: (value) {
                                        final newPosition = Duration(
                                          milliseconds:
                                              (value * duration.inMilliseconds)
                                                  .round(),
                                        );
                                        playerProvider.seek(newPosition);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(position),
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14),
                                        ),
                                        Text(
                                          _formatDuration(duration),
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Кнопка Play/Pause
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 48,
                        icon: Icon(
                          playerProvider.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          if (playerProvider.isPlaying) {
                            playerProvider.pause();
                          } else {
                            playerProvider.resume();
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Нижние кнопки
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          /// СКАЧАТЬ
                          IconButton(
                            iconSize: 28,
                            onPressed: () {
                              if (widget.track.localPath == null) {
                                playerProvider.downloadTrack(widget.track);
                              }
                            },
                            icon: Icon(
                              widget.track.localPath != null
                                  ? Icons.download_done
                                  : Icons.download,
                              color: Colors.white70,
                            ),
                          ),

                          /// ДОБАВИТЬ В ПЛЕЙЛИСТ
                          IconButton(
                            iconSize: 28,
                            icon: const Icon(Icons.playlist_add,
                                color: Colors.white70),
                            onPressed: () {
                              _showAddToPlaylistDialog(context, widget.track);
                            },
                          ),

                          /// ИЗБРАННОЕ (с мягким цветом)
                          FutureBuilder<bool>(
                            future: playerProvider.isFavorite(widget.track),
                            builder: (context, snapshot) {
                              final isFavorite = snapshot.data ?? false;
                              return StreamBuilder<List<int>>(
                                stream: playerProvider.favoritesStream,
                                initialData: playerProvider.playlists
                                    .firstWhere((p) => p.name == 'Favorites')
                                    .trackIds,
                                builder: (context, streamSnapshot) {
                                  final currentIsFavorite = streamSnapshot.data
                                          ?.contains(widget.track.id) ??
                                      isFavorite;
                                  return IconButton(
                                    iconSize: 28,
                                    onPressed: () async {
                                      await playerProvider
                                          .toggleFavorite(widget.track);
                                    },
                                    icon: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Icon(
                                        currentIsFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        key: ValueKey(currentIsFavorite),
                                        color: currentIsFavorite
                                            ? Colors.red
                                            : Colors.white70,
                                        size: 28,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          /// ГРОМКОСТЬ
                          _VolumeControl(playerProvider: playerProvider),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              )
            ]));
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, Track track) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final availablePlaylists =
        playerProvider.playlists.where((p) => p.name != 'Favorites').toList();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add to Playlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: availablePlaylists.length,
                        itemBuilder: (context, index) {
                          final playlist = availablePlaylists[index];

                          return InkWell(
                            onTap: () {
                              playerProvider.addTrackToPlaylist(
                                  track, playlist);
                              Navigator.of(context).pop();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Added ${track.title} to ${playlist.name}',
                                  ),
                                  backgroundColor: Colors.black87,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.queue_music,
                                      color: Colors.white70, size: 20),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      playlist.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.add,
                                      color: Colors.white54, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VolumeControl extends StatefulWidget {
  final PlayerProvider playerProvider;

  const _VolumeControl({Key? key, required this.playerProvider})
      : super(key: key);

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl>
    with TickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _showVolumeSlider(BuildContext context) {
    if (_overlayEntry != null) {
      _hideVolumeSlider();
      return;
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + renderBox.size.width / 2 - 25,
        bottom: MediaQuery.of(context).size.height - offset.dy + 15,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 50,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      const Icon(Icons.volume_up,
                          color: Colors.white70, size: 20),
                      const SizedBox(height: 8),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: StreamBuilder<double>(
                            stream: widget.playerProvider.volumeStream,
                            builder: (context, snapshot) {
                              final volume = snapshot.data ?? 1.0;
                              return SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.white24,
                                ),
                                child: Slider(
                                  value: volume,
                                  onChanged: widget.playerProvider.setVolume,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Icon(Icons.volume_down,
                          color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();

    // Автоматически скрыть через 3 секунды
    Future.delayed(const Duration(seconds: 3), () {
      if (_overlayEntry != null) {
        _hideVolumeSlider();
      }
    });
  }

  void _hideVolumeSlider() {
    _animationController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: widget.playerProvider.volumeStream,
      builder: (context, snapshot) {
        final volume = snapshot.data ?? 1.0;
        IconData volumeIcon;

        if (volume == 0) {
          volumeIcon = Icons.volume_off;
        } else if (volume < 0.5) {
          volumeIcon = Icons.volume_down;
        } else {
          volumeIcon = Icons.volume_up;
        }

        return IconButton(
          icon: Icon(volumeIcon, color: Colors.white70, size: 24),
          onPressed: () => _showVolumeSlider(context),
        );
      },
    );
  }
}
