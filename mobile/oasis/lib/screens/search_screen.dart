import 'package:flutter/material.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/services/api_service.dart';
import 'package:oasis/widgets/glass_card.dart';
import 'package:oasis/widgets/track_tile.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<Track> _searchResults = [];
  bool _isLoading = false;
  bool _isPaginating = false;
  bool _hasMore = true;
  int _offset = 0;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isPaginating &&
        _hasMore) {
      _performSearch(_currentQuery, paginate: true);
    }
  }

  void _performSearch(String query, {bool paginate = false}) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _currentQuery = '';
        _offset = 0;
        _hasMore = true;
      });
      return;
    }

    if (paginate) {
      setState(() => _isPaginating = true);
    } else {
      setState(() {
        _isLoading = true;
        _searchResults = [];
        _offset = 0;
        _hasMore = true;
        _currentQuery = query;
      });
    }

    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.performSafeCall(() async {
        final results =
            await _apiService.search(_currentQuery, offset: _offset);
        if (mounted) {
          setState(() {
            if (results.isNotEmpty) {
              _searchResults.addAll(results);
              _offset += results.length;
            } else {
              _hasMore = false;
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPaginating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'e x p l o r e',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _performSearch,
                  decoration: const InputDecoration(
                    hintText: 'Artists or songs',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : _searchResults.isEmpty && _currentQuery.isEmpty
                        ? _buildBrowseAll()
                        : _buildResultsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_searchResults.isEmpty) {
      return const Center(
          child: Text("No results found",
              style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _searchResults.length + (_isPaginating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _searchResults.length) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator()));
        }

        final track = _searchResults[index];
        final player = Provider.of<PlayerProvider>(context); // watch
        final isCurrent = player.currentTrack?.id == track.id;

        return TrackTile(
          track: track,
          isCurrent: isCurrent,
          isPlaying: isCurrent && player.isPlaying,
          onTap: () async {
            await context.read<AuthProvider>().performSafeCall(() async {
              await player.play(track);
            });
          },
          // Кнопка добавления в плейлист
          trailing: IconButton(
            icon: const Icon(Icons.playlist_add, color: Colors.white70),
            onPressed: () => _showAddToPlaylistDialog(context, track),
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

  Widget _buildBrowseAll() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 4 : 2;
    final categories = [
      'Pop',
      'Rock',
      'Jazz',
      'Electronic',
      'Classical',
      'Hip Hop'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Browse all',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w300)),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            itemCount: categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 15.0,
              mainAxisSpacing: 15.0,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              return GlassCard(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.primaries[index % Colors.primaries.length]
                        .withOpacity(0.4),
                  ),
                  child: Center(
                    child: Text(
                      categories[index],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
