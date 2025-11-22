import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/screens/home_screen.dart';
import 'package:oasis/screens/library_screen.dart';
import 'package:oasis/screens/player_screen.dart';
import 'package:oasis/screens/search_screen.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oasis/models/playlist.dart';
import 'package:oasis/models/track.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [PlaylistSchema, TrackSchema],
    directory: dir.path,
    inspector: true,
  );

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(MainApp(isar: isar));
}

class MainApp extends StatelessWidget {
  final Isar isar;
  const MainApp({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlayerProvider(isar: isar),
      child: MaterialApp(
        title: 'Oasis',
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlueAccent,
        ),
        useMaterial3: true,
      ),
      home: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Desktop layout
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF65A6F3), Color(0xFF80B5F5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _onItemTapped,
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      selectedIconTheme:
                          const IconThemeData(color: Colors.white),
                      unselectedIconTheme:
                          const IconThemeData(color: Colors.white70),
                      selectedLabelTextStyle:
                          const TextStyle(color: Colors.white),
                      unselectedLabelTextStyle:
                          const TextStyle(color: Colors.white70),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.home),
                          label: Text('Home'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.search),
                          label: Text('Explore'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.library_music),
                          label: Text('Library'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              children: _widgetOptions,
                            ),
                          ),
                          const PlayerScreen(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Mobile layout
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 155, 182, 214), Color.fromARGB(255, 121, 163, 214)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Scaffold(
                extendBody: true,
                body: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  children: _widgetOptions,
                ),
                bottomNavigationBar: Consumer<PlayerProvider>(
                  builder: (context, playerProvider, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PlayerScreen(),
                        if (playerProvider.currentTrack != null)
                          const SizedBox(height: 12.0),
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: BottomNavigationBar(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              elevation: 0,
                              selectedItemColor: Colors.white,
                              unselectedItemColor: Colors.white70,
                              items: const <BottomNavigationBarItem>[
                                BottomNavigationBarItem(
                                  icon: Icon(Icons.home),
                                  label: 'Home',
                                ),
                                BottomNavigationBarItem(
                                  icon: Icon(Icons.search),
                                  label: 'Explore',
                                ),
                                BottomNavigationBarItem(
                                  icon: Icon(Icons.library_music),
                                  label: 'Library',
                                ),
                              ],
                              currentIndex: _selectedIndex,
                              onTap: _onItemTapped,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
