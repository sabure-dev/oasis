import 'dart:io';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/providers/theme_provider.dart';
import 'package:oasis/widgets/glass_card.dart';
import 'package:provider/provider.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final tracks = await playerProvider.isar.tracks
        .filter()
        .localPathIsNotNull()
        .findAll();

    final validTracks = <Track>[];
    for (var track in tracks) {
      if (track.localPath != null && await File(track.localPath!).exists()) {
        validTracks.add(track);
      }
    }

    if (mounted) {
      setState(() {
        _tracks = validTracks;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTrack(Track track) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    await playerProvider.removeDownload(track);
    _loadDownloads();
  }

  Future<void> _deleteAll(Color primaryColor) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete All?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will remove all downloaded music from your device.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: primaryColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await playerProvider.clearAllDownloads();
      if (mounted) {
        _loadDownloads();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All downloads deleted'),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final primaryColor = theme.startColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.startColor, theme.endColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Downloads', style: TextStyle(color: Colors.white)),
          actions: [
            if (_tracks.isNotEmpty)
              IconButton(
                // Эта иконка белая полупрозрачная (Colors.white70)
                icon: const Icon(Icons.delete_sweep, color: Colors.white70),
                onPressed: () => _deleteAll(primaryColor),
                tooltip: "Delete All",
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tracks.isEmpty
                ? const Center(
                    child: Text(
                      'No downloads yet',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _tracks.length,
                    itemBuilder: (context, index) {
                      final track = _tracks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          child: ListTile(
                            // --- ИСПРАВЛЕНИЕ 2: Скругляем эффекты нажатия ---
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                track.albumCover,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.white10,
                                  child: const Icon(Icons.music_note,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            title: Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.white70),
                              onPressed: () => _deleteTrack(track),
                            ),
                            onTap: () {
                               Provider.of<PlayerProvider>(context, listen: false)
                                  .play(track, playlist: _tracks);
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}