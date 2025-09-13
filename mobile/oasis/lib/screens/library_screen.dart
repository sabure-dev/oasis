import 'package:flutter/material.dart';
import 'package:oasis/widgets/glass_card.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 5
        : screenWidth > 800
            ? 4
            : screenWidth > 600
                ? 3
                : 2;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'l i b r a r y',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 20),
                const TabBar(
                  tabs: [
                    Tab(text: 'Playlists'),
                    Tab(text: 'Artists'),
                    Tab(text: 'Albums'),
                  ],
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: TabBarView(
                    children: [
                      GridView.builder(
                        itemCount: 15, // Placeholder
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 15.0,
                          mainAxisSpacing: 15.0,
                          childAspectRatio: 1.2,
                        ),
                        itemBuilder: (context, index) {
                          return const GlassCard(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.playlist_play,
                                    size: 40, color: Colors.white),
                                SizedBox(height: 10),
                                Text('My Playlist',
                                    style: TextStyle(color: Colors.white)),
                                Text('123 songs',
                                    style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          );
                        },
                      ),
                      const Center(
                          child: Text('Artists',
                              style: TextStyle(color: Colors.white))),
                      const Center(
                          child: Text('Albums',
                              style: TextStyle(color: Colors.white))),
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
