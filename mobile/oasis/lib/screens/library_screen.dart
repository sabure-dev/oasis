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
                          final playlists = playerProvider.playlists;
                          return GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 1,
                            ),
                            itemCount: playlists.length + 1,
                            itemBuilder: (context, index) {
                              if (index == playlists.length) {
                                return InkWell(
                                  onTap: () => _showCreatePlaylistDialog(context),
                                  child: GlassCard(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            size: 38.0,
                                            color: Theme.of(context).colorScheme.onSecondary,
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'New Playlist',
                                            style: TextStyle(color: Colors.white, fontSize: 18),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 5),
                                          const Text(
                                            '', // No song count for create button
                                            style: TextStyle(color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final playlist = playlists[index];
                              return GestureDetector(
                                onLongPress: () {
                                  if (playlist.name != 'Favorites') {
                                    _showDeletePlaylistDialog(context, playerProvider, playlist);
                                  }
                                },
                                child: InkWell(
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
                                          Icon(
                                            index == 0 ? Icons.favorite : Icons.music_note, // 0 - это Избранное
                                            size: 38.0,
                                            color: Theme.of(context).colorScheme.onSecondary,
                                          ),
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
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () => _showCreatePlaylistDialog(context),
        //   backgroundColor: Colors.blueAccent,
        //   child: const Icon(Icons.add, color: Colors.white),
        // ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final TextEditingController _playlistNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Playlist'),
          content: TextField(
            controller: _playlistNameController,
            decoration: const InputDecoration(hintText: 'Playlist Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_playlistNameController.text.isNotEmpty) {
                  Provider.of<PlayerProvider>(context, listen: false).createPlaylist(_playlistNameController.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showDeletePlaylistDialog(BuildContext context, PlayerProvider playerProvider, Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Playlist'),
          content: Text('Are you sure you want to delete playlist "${playlist.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                playerProvider.deletePlaylist(playlist);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
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
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white70),
                      onPressed: () {
                        playerProvider.removeTrackFromPlaylist(track, playlist);
                      },
                    ),
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
