import 'package:flutter/material.dart';
import 'package:oasis/providers/player_provider.dart';
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
                  title: Text(track.title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(track.artist, style: const TextStyle(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.volume_up, color: Colors.white),
                      StreamBuilder<double>(
                        stream: playerProvider.volumeStream,
                        builder: (context, snapshot) {
                          final volume = snapshot.data ?? 1.0;
                          return SizedBox(
                            width: 100,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                overlayColor: Colors.transparent,
                                overlayShape: SliderComponentShape.noOverlay,
                              ),
                              child: Slider(
                                value: volume,
                                onChanged: playerProvider.setVolume,
                                activeColor: Colors.white,
                                inactiveColor: Colors.white38,
                              ),
                            ),
                          );
                        },
                      ),
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
}