import 'dart:io';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/providers/auth_provider.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/providers/theme_provider.dart';
import 'package:oasis/screens/downloads_screen.dart'; // <--- Импорт
import 'package:oasis/screens/theme_selection_screen.dart';
import 'package:oasis/widgets/glass_card.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _cacheSize = "Calculating...";
  String _songsCount = ""; // Добавим счетчик треков

  @override
  void initState() {
    super.initState();
    _calculateDownloadsSize();
  }

  // Обновляем данные при возвращении на экран (например, после удаления треков)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateDownloadsSize();
  }

  Future<void> _calculateDownloadsSize() async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final isar = playerProvider.isar;

    final downloadedTracks =
        await isar.tracks.filter().localPathIsNotNull().findAll();

    int totalBytes = 0;
    int count = 0;

    for (var track in downloadedTracks) {
      if (track.localPath != null) {
        final file = File(track.localPath!);
        if (await file.exists()) {
          totalBytes += await file.length();
          count++;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      if (count == 0) {
        _cacheSize = "Empty";
        _songsCount = "";
      } else {
        _cacheSize = "${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB";
        _songsCount = "• $count songs";
      }
    });
  }

  // Метод очистки истории (оставляем тут, он простой)
  Future<void> _clearHistory(Color primaryColor) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    try {
      await playerProvider.clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Listening history cleared'),
              backgroundColor: primaryColor),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  void _handleLogout(BuildContext context) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await playerProvider.clearDataOnLogout();

      await authProvider.logout();
    } catch (e) {
      print("Logout error: $e");
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.currentTheme.startColor;
    final user = authProvider.currentUser;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ... (Заголовок и Карточка профиля как были) ...
                    const Text('p r o f i l e',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w400)),
                    const SizedBox(height: 30),
                    Center(
                      child: GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(children: [
                            const CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.person,
                                    size: 40, color: Colors.white)),
                            const SizedBox(height: 15),
                            Text(user?.username ?? 'Loading...',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(user?.email ?? '',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- STORAGE ---
                    _buildSectionHeader('Storage & Data'),

                    // Кнопка Downloads теперь ведет на экран управления
                    _buildSettingsTile(
                      context,
                      icon: Icons.offline_pin_outlined,
                      title: 'Downloads',
                      subtitle: _cacheSize == "Empty"
                          ? "No downloads"
                          : "$_cacheSize $_songsCount",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DownloadsScreen()),
                        ).then((_) =>
                            _calculateDownloadsSize()); // Обновляем размер при возврате
                      },
                    ),

                    // Очистка истории
                    _buildSettingsTile(
                      context,
                      icon: Icons.history,
                      title: 'Clear History',
                      subtitle: 'Remove listened tracks history',
                      onTap: () =>
                          _showClearHistoryDialog(context, primaryColor),
                    ),

                    const SizedBox(height: 20),

                    // --- APP SETTINGS ---
                    _buildSectionHeader('App Settings'),
                    // ... (Appearance и About как были) ...
                    _buildSettingsTile(
                      context,
                      icon: Icons.palette,
                      title: 'Appearance',
                      subtitle: 'Change app themes',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ThemeSelectionScreen()));
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.info_outline,
                      title: 'About Oasis',
                      subtitle: 'Version 1.0.0',
                      onTap: () => _showAboutDialog(context, primaryColor),
                    ),

                    const Spacer(),
                    const SizedBox(height: 20),

                    // ... (Кнопка Logout как была) ...
                    GlassCard(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16.0),
                          onTap: () {
                            // ... (код диалога logout) ...
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.grey[900],
                                title: const Text('Logout',
                                    style: TextStyle(color: Colors.white)),
                                content: const Text(
                                    'Are you sure you want to logout?',
                                    style: TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel',
                                          style: TextStyle(
                                              color: Colors.white54))),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(
                                            context); // Закрываем вопрос "Вы уверены?"
                                        _handleLogout(
                                            context); // <--- Запускаем полную очистку
                                      },
                                      style: TextButton.styleFrom(
                                          foregroundColor: primaryColor),
                                      child: const Text('Logout')),
                                ],
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Logout',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500))
                                ]),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (Остальные методы: _buildSectionHeader, _buildSettingsTile, диалоги) ...
  // Убедитесь, что _showClearHistoryDialog и другие вспомогательные методы остались в классе
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w300),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GlassCard(
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Icon(icon, color: Colors.white70),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          subtitle:
              Text(subtitle, style: const TextStyle(color: Colors.white54)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text('Clear History?', style: TextStyle(color: Colors.white)),
        content: const Text('This will clear your "Recently Listened" tracks.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearHistory(primaryColor);
            },
            style: TextButton.styleFrom(foregroundColor: primaryColor),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('About Oasis', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Oasis Music App',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Version 1.0.0', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 4),
            Text('© 2025 Oasis Music', style: TextStyle(color: Colors.white54)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: primaryColor),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
