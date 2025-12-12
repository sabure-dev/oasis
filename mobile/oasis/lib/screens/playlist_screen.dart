import 'package:flutter/material.dart';
import 'package:oasis/models/playlist.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/providers/theme_provider.dart';
import 'package:oasis/widgets/track_tile.dart';
import 'package:provider/provider.dart';

class PlaylistScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistScreen({super.key, required this.playlist});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<Track>? _tracks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final tracks = await Provider.of<PlayerProvider>(context, listen: false)
        .getTracksForPlaylist(widget.playlist);

    if (mounted) {
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final gradient = LinearGradient(
          colors: [
            themeProvider.currentTheme.startColor,
            themeProvider.currentTheme.endColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

        return Container(
          decoration: BoxDecoration(gradient: gradient),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              centerTitle: true,
              title: Text(widget.playlist.name,
                  style: const TextStyle(color: Colors.white)),
              actions: [
                if (widget.playlist.name != 'Favorites')
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _showDeleteDialog(context),
                  ),
              ],
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _tracks == null || _tracks!.isEmpty
                    ? _buildEmptyState()
                    : CustomScrollView(
                        slivers: [
                          // Шапка плейлиста
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: widget.playlist.coverImage.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Image.network(
                                                widget.playlist.coverImage,
                                                fit: BoxFit.cover),
                                          )
                                        : Icon(
                                            widget.playlist.name == 'Favorites'
                                                ? Icons.favorite
                                                : Icons.music_note,
                                            size: 60,
                                            color: Colors.white54,
                                          ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    widget.playlist.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_tracks!.length} tracks',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (_tracks!.isNotEmpty) {
                                        context.read<PlayerProvider>().play(
                                            _tracks!.first,
                                            playlist: _tracks!);
                                      }
                                    },
                                    icon: const Icon(Icons.play_arrow,
                                        color: Colors.black),
                                    label: const Text('Play All'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Список треков
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final track = _tracks![index];

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Dismissible(
                                    key: Key(
                                        '${widget.playlist.id}_${track.id}'),
                                    direction: DismissDirection.endToStart,
                                    // Свайп только влево

                                    // --- ИСПРАВЛЕНИЯ ЗДЕСЬ ---
                                    background: Container(
                                      // 1. Компенсируем отступ TrackTile (bottom: 8),
                                      // чтобы фон был ровно под карточкой
                                      margin:
                                          const EdgeInsets.only(bottom: 8.0),

                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        // 2. Цвет такой же, как у GlassCard, чтобы не было "темной дыры"
                                        color:
                                            Colors.white.withValues(alpha: 0.0),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),

                                      // 3. Текст теперь будет ровно по центру карточки
                                      child: const Text(
                                        "Delete",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14),
                                      ),
                                    ),
                                    // --------------------------

                                    onDismissed: (direction) {
                                      setState(() {
                                        _tracks!.removeAt(index);
                                      });
                                      Provider.of<PlayerProvider>(context,
                                              listen: false)
                                          .removeTrackFromPlaylist(
                                              track, widget.playlist);
                                    },

                                    child: Consumer<PlayerProvider>(
                                      builder: (context, player, _) {
                                        final isCurrent =
                                            player.currentTrack?.id == track.id;
                                        return TrackTile(
                                          track: track,
                                          isCurrent: isCurrent,
                                          isPlaying:
                                              isCurrent && player.isPlaying,
                                          onTap: () => player.play(track,
                                              playlist: _tracks!),
                                          trailing: null,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              childCount: _tracks!.length,
                            ),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 100)),
                        ],
                      ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, size: 64, color: Colors.white30),
          const SizedBox(height: 16),
          Text(
            'No tracks yet',
            style:
                TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Playlist?',
            style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<PlayerProvider>().deletePlaylist(widget.playlist);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
