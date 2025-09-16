import 'package:flutter/material.dart';
import 'package:oasis/models/playlist.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/widgets/glass_card.dart';
import 'package:provider/provider.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 5
        : screenWidth > 800
            ? 4
            : screenWidth > 600
                ? 3
                : 2;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(right: 20.0, left: 20.0, top: 20.0,),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'l i b r a r y',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 20),
                const TabBar(
                  tabs: [
                    Tab(text: 'Playlists'),
                    Tab(text: 'Artists'),
                    Tab(text: 'Albums'),
                  ],
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: TabBarView(
                    children: [
                      Consumer<PlayerProvider>(
                        builder: (context, playerProvider, child) {
                          final playlists = [playerProvider.favoritesPlaylist]; // Add other playlists here
                          return GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 1,
                            ),
                            itemCount: playlists.length,
                            itemBuilder: (context, index) {
                              final playlist = playlists[index];
                              return InkWell(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: playlist)));
                                },
                                child: GlassCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.favorite, color: Colors.white, size: 40),
                                        const SizedBox(height: 10),
                                        Text(
                                          playlist.name,
                                          style: const TextStyle(color: Colors.white, fontSize: 18),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${playlist.tracks.length} songs',
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const Center(
                          child: Text('Artists',
                              style: TextStyle(color: Colors.white))),
                      const Center(
                          child: Text('Albums',
                              style: TextStyle(color: Colors.white))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlaylistScreen extends StatelessWidget {
  final Playlist playlist;
  const PlaylistScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF65A6F3),
      appBar: AppBar(
        title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, playerProvider, child) {
          if (playlist.tracks.isEmpty) {
            return const Center(
              child: Text(
                'This playlist is empty.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return ListView.builder(
            itemCount: playlist.tracks.length,
            itemBuilder: (context, index) {
              final track = playlist.tracks[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: GlassCard(
                  child: ListTile(
                    title: Text(track.title, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(track.artist, style: const TextStyle(color: Colors.white70)),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.network(track.albumCover, width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    onTap: () {
                      playerProvider.play(track, playlist: playlist.tracks);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
