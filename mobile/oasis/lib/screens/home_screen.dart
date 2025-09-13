import 'package:flutter/material.dart';
import 'package:oasis/widgets/glass_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'), // Убедитесь, что вы добавили это изображение
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'o a s i s',
                  style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 20),

                // Unified layout for both mobile and desktop
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your playlists',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 180, // Height for square elements
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 15, // Placeholder
                          itemBuilder: (context, index) {
                            return const Padding(
                              padding: EdgeInsets.only(right: 15.0),
                              child: SizedBox(
                                width: 180, // Width for square elements
                                child: GlassCard(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.music_note, size: 40, color: Colors.white),
                                      SizedBox(height: 10),
                                      Text('Playlist', style: TextStyle(color: Colors.white)),
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
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300),
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 15, // Placeholder
                          itemBuilder: (context, index) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 10.0),
                              child: GlassCard(
                                child: ListTile(
                                  leading: Icon(Icons.album, color: Colors.white, size: 40),
                                  title: Text('Song Title', style: TextStyle(color: Colors.white)),
                                  subtitle: Text('Artist', style: TextStyle(color: Colors.white70)),
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
      ),
    );

  }
}