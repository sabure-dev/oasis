import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oasis/models/track.dart';
import 'package:oasis/widgets/glass_card.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final bool isPlaying;
  final bool isCurrent;
  final Widget? trailing;
  final String? subtitle;

  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.isPlaying = false,
    this.isCurrent = false,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: GlassCard(
          // Оборачиваем в Material для правильной отрисовки чернильных эффектов (InkWell)
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              onTap: onTap,
              // [FIX] Закругляем эффекты наведения/нажатия
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              // ------------------------------------------
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              dense: true,

              // --- ОБЛОЖКА С ОВЕРЛЕЕМ ---
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    children: [
                      // 1. Сама картинка (фоном)
                      Positioned.fill(
                        child: Image.network(
                          track.albumCover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white10,
                            child: const Icon(Icons.music_note,
                                color: Colors.white),
                          ),
                        ),
                      ),

                      // 2. Затемнение (только если играет)
                      if (isCurrent && isPlaying)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black
                                .withOpacity(0.4), // Полупрозрачный черный
                          ),
                        ),

                      // 3. Анимация (по центру)
                      if (isCurrent && isPlaying)
                        const Center(
                          child: _PlayingIndicator(color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
              // ---------------------------

              title: Text(
                track.title,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 15,
                    letterSpacing: isCurrent ? 2 : 0.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              subtitle: Text(
                subtitle ?? track.artist,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // В trailing теперь просто кнопка или время, анимация переехала влево
              trailing: trailing ??
                  Text(
                    track.formattedDuration,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
            ),
          ),
        ));
  }
}

// --- ВИДЖЕТ АНИМАЦИИ ---
class _PlayingIndicator extends StatefulWidget {
  final Color color;

  const _PlayingIndicator({required this.color});

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 12,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(0),
              _buildBar(1),
              _buildBar(2),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBar(int index) {
    final double t = _controller.value;
    final double heightFactor =
        (math.sin((t * math.pi * 2) + (index * 2)) + 1) / 2;
    final double height = 2.0 + (10.0 * heightFactor);

    return Container(
      width: 4, // Столбики чуть тоньше
      height: height,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
