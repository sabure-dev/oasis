import 'package:flutter/material.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/screens/playlist_screen.dart';
import 'package:oasis/screens/theme_selection_screen.dart';
import 'package:oasis/widgets/playlist_card.dart';
import 'package:oasis/widgets/track_tile.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final playlists = playerProvider.playlists;
    final recentTracks = playerProvider.recentTracks;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'o a s i s',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ThemeSelectionScreen()),
                    ),
                    icon: const Icon(Icons.palette, color: Colors.white),
                    tooltip: 'Themes',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Playlists Section
              const Text(
                'Your playlists',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 180,
                child: playlists.isEmpty
                    ? const Center(
                        child: Text('No playlists yet',
                            style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 15.0),
                            child: PlaylistCard(
                              playlist: playlist,
                              onTap: () {
                                // ПЕРЕХОД НА ЭКРАН ПЛЕЙЛИСТА
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PlaylistScreen(playlist: playlist),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 20),

              // Recently Played Section
              const Text(
                'Listened to recently',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: recentTracks.isEmpty
                    ? const Center(
                        child: Text('Start listening...',
                            style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: recentTracks.length,
                        itemBuilder: (context, index) {
                          final track = recentTracks[index];

                          // Определяем состояние этого конкретного трека
                          final isCurrent =
                              playerProvider.currentTrack?.id == track.id;
                          final isPlaying =
                              isCurrent && playerProvider.isPlaying;

                          return TrackTile(
                            track: track,
                            isCurrent: isCurrent,
                            isPlaying: isPlaying,
                            onTap: () => playerProvider.play(track),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
