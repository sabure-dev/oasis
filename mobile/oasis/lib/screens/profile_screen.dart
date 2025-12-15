import 'package:flutter/material.dart';
import 'package:oasis/providers/auth_provider.dart';
import 'package:oasis/providers/theme_provider.dart'; // <--- Импорт для темы
import 'package:oasis/screens/theme_selection_screen.dart';
import 'package:oasis/widgets/glass_card.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // Получаем доступ к текущей теме
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.currentTheme.startColor;

    final user = authProvider.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'p r o f i l e',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 30),

              // Карточка пользователя
              Center(
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white24,
                          child:
                              Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          user?.username ?? 'Loading...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                'Settings',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 15),

              _buildSettingsTile(
                context,
                icon: Icons.palette,
                title: 'Appearance',
                subtitle: 'Change app themes',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ThemeSelectionScreen()),
                  );
                },
              ),

              _buildSettingsTile(
                context,
                icon: Icons.info_outline,
                title: 'About Oasis',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('About Oasis',
                          style: TextStyle(color: Colors.white)),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Oasis Music App',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Version 1.0.0',
                              style: TextStyle(color: Colors.white70)),
                          SizedBox(height: 4),
                          Text('© 2025 Oasis Music',
                              style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                              foregroundColor: primaryColor),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),

              GlassCard(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16.0),
                    onTap: () {
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
                                  style: TextStyle(color: Colors.white54)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.read<AuthProvider>().logout();
                              },
                              style: TextButton.styleFrom(
                                  foregroundColor: primaryColor),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
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
            borderRadius:
                BorderRadius.circular(16), // Скругляем эффекты наведения
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
}
