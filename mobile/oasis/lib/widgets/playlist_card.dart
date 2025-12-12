import 'package:flutter/material.dart';
import 'package:oasis/models/playlist.dart';
import 'package:oasis/widgets/glass_card.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isGrid;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onTap,
    this.onLongPress,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    // Определяем ширину в зависимости от режима (список или сетка)
    final double? width = isGrid ? null : 160;

    return SizedBox(
      width: width,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Уменьшили padding с 12 до 8
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Обложка занимает всё свободное место
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: playlist.coverImage.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                playlist.coverImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildIcon(),
                              ),
                            )
                          : _buildIcon(),
                    ),
                  ),
                  const SizedBox(height: 8), // Уменьшили отступ с 12 до 8

                  // Текстовый блок (без Expanded, чтобы не было overflow)
                  Column(
                    children: [
                      Text(
                        playlist.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15, // Чуть уменьшили шрифт
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${playlist.trackIds.length} tracks',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Icon(
      playlist.name == 'Favorites' ? Icons.favorite : Icons.music_note,
      size: 40,
      color: Colors.white70,
    );
  }
}
