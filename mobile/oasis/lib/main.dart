import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:oasis/models/gradient_theme.dart';
import 'package:oasis/models/playlist.dart';
import 'package:oasis/providers/auth_provider.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/providers/theme_provider.dart';
import 'package:oasis/screens/home_screen.dart';
import 'package:oasis/screens/library_screen.dart';
import 'package:oasis/screens/login_screen.dart';
import 'package:oasis/screens/player_screen.dart';
import 'package:oasis/screens/profile_screen.dart';
import 'package:oasis/screens/search_screen.dart';
import 'package:oasis/screens/verification_screen.dart';
import 'package:oasis/services/audio_player_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'models/track.dart';

late AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [PlaylistSchema, TrackSchema, GradientThemeModelSchema],
    directory: dir.path,
    inspector: true,
  );

  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.oasis.channel.audio',
      androidNotificationChannelName: 'Oasis Music',
      androidNotificationOngoing: true,
    ),
  );

  final themeProvider = ThemeProvider(isar: isar);
  await themeProvider.initialize();
  final authProvider = AuthProvider();

  runApp(MainApp(
      isar: isar,
      themeProvider: themeProvider,
      authProvider: authProvider,
      audioHandler: audioHandler // Передаем handler в App
      ));
}

class MainApp extends StatelessWidget {
  final Isar isar;
  final ThemeProvider themeProvider;
  final AuthProvider authProvider;
  final AudioHandler audioHandler; // Добавляем поле

  const MainApp({
    super.key,
    required this.isar,
    required this.themeProvider,
    required this.authProvider,
    required this.audioHandler, // Добавляем в конструктор
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PlayerProvider>(
          // Передаем audioHandler в провайдер
          create: (_) => PlayerProvider(isar: isar, audioHandler: audioHandler),
        ),
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
        ),
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
        ),
      ],
      // Оборачиваем MaterialApp в Consumer, чтобы иметь доступ к AuthProvider
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return MaterialApp(
                key: ValueKey(auth.isAuthenticated),
                title: 'Oasis',
                debugShowCheckedModeBanner: false,
                theme: // Внутри Consumer<ThemeProvider>
                    ThemeData(
                  brightness: Brightness.light,
                  scaffoldBackgroundColor: Colors.transparent,
                  canvasColor: Colors.transparent,

                  // --- ДОБАВЛЕНО: Настройка цветов ---
                  primaryColor: theme.currentTheme.startColor,
                  // Основной цвет
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: theme.currentTheme.startColor,
                    // Генерируем палитру от цвета темы
                    brightness: Brightness.light,
                    primary:
                        theme.currentTheme.startColor, // Цвет кнопок и акцентов
                  ),

                  // Цвет курсора и выделения текста
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: Colors.white,
                    // Белый курсор (или theme.currentTheme.startColor)
                    selectionColor:
                        theme.currentTheme.startColor.withOpacity(0.3),
                    selectionHandleColor: theme.currentTheme.startColor,
                  ),

                  inputDecorationTheme: const InputDecorationTheme(
                    labelStyle: TextStyle(color: Colors.white70),
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  // ------------------------------------

                  tabBarTheme: const TabBarThemeData(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                  ),
                  useMaterial3: true,
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android:
                          FadeUpwardsPageTransitionsBuilder(),
                      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    },
                  ),
                ),
                home: auth.isLoading
                    ? const Scaffold(
                        body: Center(child: CircularProgressIndicator()))
                    : _buildHome(auth, theme),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHome(AuthProvider auth, ThemeProvider theme) {
    // Вспомогательный виджет для градиентного фона
    Widget withGradient(Widget child) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.currentTheme.startColor,
              theme.currentTheme.endColor
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: child,
      );
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Если авторизован, но профиль еще грузится -> показываем красивый лоадер
    if (auth.currentUser == null) {
      return withGradient(
        const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    if (auth.currentUser!.isVerified) {
      return const AppShell();
    } else {
      return const VerificationScreen();
    }
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
    ProfileScreen(),
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final gradient = LinearGradient(
          colors: [
            themeProvider.currentTheme.startColor,
            themeProvider.currentTheme.endColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return Container(
                decoration: BoxDecoration(gradient: gradient),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
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
                          NavigationRailDestination(
                            icon: Icon(Icons.person),
                            label: Text('Profile'),
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
              return Container(
                decoration: BoxDecoration(gradient: gradient),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
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
                              filter: ImageFilter.blur(
                                sigmaX: 10.0,
                                sigmaY: 10.0,
                              ),
                              child: BottomNavigationBar(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
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
                                  // --- Добавлено ---
                                  BottomNavigationBarItem(
                                    icon: Icon(Icons.person),
                                    label: 'Profile',
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
        );
      },
    );
  }
}
