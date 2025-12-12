import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
// Убираем импорт just_audio_background
import 'package:oasis/models/gradient_theme.dart';
import 'package:oasis/models/playlist.dart';
import 'package:oasis/providers/auth_provider.dart';
import 'package:oasis/providers/player_provider.dart';
import 'package:oasis/providers/theme_provider.dart';
import 'package:oasis/screens/home_screen.dart';
import 'package:oasis/screens/library_screen.dart';
import 'package:oasis/screens/login_screen.dart';
import 'package:oasis/screens/player_screen.dart';
import 'package:oasis/screens/search_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'models/track.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [PlaylistSchema, TrackSchema, GradientThemeModelSchema],
    directory: dir.path,
    inspector: true,
  );

  final themeProvider = ThemeProvider(isar: isar);
  await themeProvider.initialize();
  final authProvider = AuthProvider();

  runApp(MainApp(
      isar: isar, themeProvider: themeProvider, authProvider: authProvider));
}

class MainApp extends StatelessWidget {
  final Isar isar;
  final ThemeProvider themeProvider;
  final AuthProvider authProvider;

  const MainApp({
    super.key,
    required this.isar,
    required this.themeProvider,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PlayerProvider>(
          create: (_) => PlayerProvider(isar: isar),
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
                // ВАЖНО: Этот ключ заставляет Flutter пересоздать MaterialApp (и сбросить навигатор)
                // при смене статуса авторизации. Это решает проблему "застревания".
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

                  // Стиль полей ввода (чтобы убрать фиолетовый underline)
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
                // Логика выбора экрана
                home: auth.isLoading
                    ? const Scaffold(
                        body: Center(child: CircularProgressIndicator()))
                    : (auth.isAuthenticated
                        ? const AppShell()
                        : const LoginScreen()),
              );
            },
          );
        },
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
