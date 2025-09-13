import 'package:flutter/material.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/widgets/glass_card.dart';
import 'package:provider/provider.dart';

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

        return GlassCard(
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: Image.network(track.albumCover, width: 50, height: 50, fit: BoxFit.cover),
            ),
            title: Text(track.title, style: const TextStyle(color: Colors.white)),
            subtitle: Text(track.artist, style: const TextStyle(color: Colors.white70)),
            trailing: IconButton(
              icon: Icon(playerProvider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
              onPressed: () {
                if (playerProvider.isPlaying) {
                  playerProvider.pause();
                } else {
                  playerProvider.resume();
                }
              },
            ),
          ),
        );
      },
    );
  }
}