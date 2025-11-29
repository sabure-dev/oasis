import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/widgets/glass_card.dart';
import 'package:oasis/screens/theme_selection_screen.dart';
import 'package:oasis/providers/theme_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0, left: 20.0, top: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'o a s i s',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ThemeSelectionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.palette),
                    color: Colors.white,
                    tooltip: 'Customize Theme',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your playlists',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 15,
                        itemBuilder: (context, index) {
                          return const Padding(
                            padding: EdgeInsets.only(right: 15.0),
                            child: SizedBox(
                              width: 180,
                              child: GlassCard(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.music_note,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Playlist',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Listened to recently',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 15,
                        itemBuilder: (context, index) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 10.0),
                            child: GlassCard(
                              child: ListTile(
                                leading: Icon(
                                  Icons.album,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                title: Text(
                                  'Song Title',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  'Artist',
                                  style: TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  });
}}