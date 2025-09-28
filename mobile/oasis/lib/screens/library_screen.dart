import 'package:flutter/material.dart';
import 'package:oasis/models/playlist.dart';
import 'package:oasis/models/track.dart';
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
                                            '${playlist.trackIds.length} songs',
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

class PlaylistScreen extends StatefulWidget {
  final Playlist playlist;
  const PlaylistScreen({super.key, required this.playlist});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Scaffold(
      
      backgroundColor: const Color.fromARGB(248, 138, 180, 222),
      appBar: AppBar(
        title: Text(
          widget.playlist.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: FutureBuilder<List<Track>>(
          future: playerProvider.getTracksForPlaylist(widget.playlist),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note_outlined,
                      size: 64,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tracks in this playlist yet.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final tracks = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Playlist header
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: Icon(
                          widget.playlist.name == 'Favorites' 
                              ? Icons.favorite 
                              : Icons.queue_music,
                          size: 36,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.playlist.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Play all button
                if (tracks.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        playerProvider.play(tracks.first, playlist: tracks);
                      },
                      icon: const Icon(Icons.play_arrow, color: Colors.black),
                      label: const Text(
                        'Play All',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),

                // Tracks list
                Expanded(
                  child: ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final isCurrentTrack = playerProvider.currentTrack?.id == track.id;
                      
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isCurrentTrack 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  track.albumCover,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        Icons.music_note,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (isCurrentTrack)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.black.withOpacity(0.4),
                                    ),
                                    child: const Icon(
                                      Icons.equalizer,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            track.title,
                            style: TextStyle(
                              color: isCurrentTrack ? Colors.white : Colors.white,
                              fontSize: 16,
                              fontWeight: isCurrentTrack ? FontWeight.w600 : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            track.artist,
                            style: TextStyle(
                              color: isCurrentTrack 
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatDuration(track.duration ?? 0),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  if (isCurrentTrack && playerProvider.isPlaying) {
                                    playerProvider.pause();
                                  } else {
                                    playerProvider.play(track, playlist: tracks);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    (isCurrentTrack && playerProvider.isPlaying) 
                                        ? Icons.pause 
                                        : Icons.play_arrow,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            if (isCurrentTrack && playerProvider.isPlaying) {
                              playerProvider.pause();
                            } else {
                              playerProvider.play(track, playlist: tracks);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}