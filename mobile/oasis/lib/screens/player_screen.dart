import 'package:flutter/material.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/widgets/glass_card.dart';
import 'package:provider/provider.dart';

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

        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.network(track.albumCover, width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  title: Text(
                    track.title,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  subtitle: Text(
                    track.artist,
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          playerProvider.isFavorite(track) ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          playerProvider.toggleFavorite(track);
                        },
                      ),
                      // Volume control
                      _VolumeControl(playerProvider: playerProvider),
                      IconButton(
                        icon: Icon(playerProvider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                        onPressed: () {
                          if (playerProvider.isPlaying) {
                            playerProvider.pause();
                          } else {
                            playerProvider.resume();
                          }
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'download') {
                            if (track.localPath == null) {
                              playerProvider.downloadTrack(track);
                            }
                          } else if (value == 'add_to_playlist') {
                            _showAddToPlaylistDialog(context, track);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'download',
                            child: Row(
                              children: [
                                Icon(track.localPath != null ? Icons.download_done : Icons.download, color: Colors.black),
                                const SizedBox(width: 8),
                                Text(track.localPath != null ? 'Downloaded' : 'Download'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'add_to_playlist',
                            child: Row(
                              children: [
                                Icon(Icons.playlist_add, color: Colors.black),
                                SizedBox(width: 8),
                                Text('Add to Playlist'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                StreamBuilder<Duration>(
                  stream: playerProvider.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: playerProvider.durationStream,
                      builder: (context, snapshot) {
                        final duration = snapshot.data ?? Duration.zero;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 20,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  overlayColor: Colors.transparent,
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                                  max: duration.inSeconds.toDouble(),
                                  onChanged: (value) {
                                    playerProvider.seek(Duration(seconds: value.round()));
                                  },
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white38,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, Track track) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final availablePlaylists = playerProvider.playlists.where((p) => p.name != 'Favorites').toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add to Playlist'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availablePlaylists.length,
              itemBuilder: (context, index) {
                final playlist = availablePlaylists[index];
                return ListTile(
                  title: Text(playlist.name),
                  onTap: () {
                    playerProvider.addTrackToPlaylist(track, playlist);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added ${track.title} to ${playlist.name}')),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _VolumeControl extends StatefulWidget {
  final PlayerProvider playerProvider;

  const _VolumeControl({Key? key, required this.playerProvider}) : super(key: key);

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  OverlayEntry? _overlayEntry;

  void _showVolumeSlider(BuildContext context) {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      return;
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + renderBox.size.width / 2 - 20,
        bottom: MediaQuery.of(context).size.height - offset.dy + 10,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 40,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: StreamBuilder<double>(
                stream: widget.playerProvider.volumeStream,
                builder: (context, snapshot) {
                  final volume = snapshot.data ?? 1.0;
                  return SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      overlayColor: Colors.transparent,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: volume,
                      onChanged: widget.playerProvider.setVolume,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white38,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.volume_up, color: Colors.white),
      onPressed: () => _showVolumeSlider(context),
    );
  }
}