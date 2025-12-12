import 'package:flutter/material.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/providers/theme_provider.dart';
import 'package:oasis/screens/playlist_screen.dart';
import 'package:oasis/widgets/glass_card.dart';
import 'package:oasis/widgets/playlist_card.dart';
import 'package:provider/provider.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Адаптивная сетка
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 800 ? 4 : (screenWidth > 600 ? 3 : 2);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final gradient = LinearGradient(
          colors: [
            themeProvider.currentTheme.startColor,
            themeProvider.currentTheme.endColor
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

        return DefaultTabController(
          length: 3,
          child: Container(
            decoration: BoxDecoration(gradient: gradient),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('l i b r a r y',
                          style: TextStyle(color: Colors.white, fontSize: 34)),
                      const SizedBox(height: 20),
                      const TabBar(
                        tabs: [
                          Tab(text: 'Playlists'),
                          Tab(text: 'Artists'),
                          Tab(text: 'Albums')
                        ],
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: Colors.white,
                        dividerColor: Colors.transparent,
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Вкладка Плейлистов
                            Consumer<PlayerProvider>(
                              builder: (context, player, child) {
                                return GridView.builder(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 20,
                                    childAspectRatio:
                                        0.85, // Слегка изменили для fit
                                  ),
                                  itemCount: player.playlists.length + 1,
                                  itemBuilder: (context, index) {
                                    // Кнопка "Создать новый"
                                    if (index == player.playlists.length) {
                                      return _buildAddButton(context);
                                    }

                                    final playlist = player.playlists[index];
                                    return PlaylistCard(
                                      playlist: playlist,
                                      isGrid: true,
                                      // Включаем режим сетки (растягивание по ширине)
                                      onTap: () {
                                        // ПЕРЕХОД НА ЭКРАН ПЛЕЙЛИСТА
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PlaylistScreen(
                                                playlist: playlist),
                                          ),
                                        );
                                      },
                                      onLongPress: playlist.name == 'Favorites'
                                          ? null
                                          : () => _showDeleteDialog(
                                              context, player, playlist),
                                    );
                                  },
                                );
                              },
                            ),
                            // Заглушки
                            const Center(
                                child: Text('Artists coming soon',
                                    style: TextStyle(color: Colors.white))),
                            const Center(
                                child: Text('Albums coming soon',
                                    style: TextStyle(color: Colors.white))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: () => _showCreateDialog(context),
      borderRadius: BorderRadius.circular(16),
      child: const GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 40, color: Colors.white),
            SizedBox(height: 8),
            Text('New Playlist', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // Диалоги
  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text('New Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: 'Name', hintStyle: TextStyle(color: Colors.white54)),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<PlayerProvider>(context, listen: false)
                    .createPlaylist(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, PlayerProvider player, dynamic playlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete?', style: TextStyle(color: Colors.white)),
        content: Text('Delete playlist "${playlist.name}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              player.deletePlaylist(playlist);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
