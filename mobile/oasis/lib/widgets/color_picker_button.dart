import 'package:flutter/material.dart';

class ColorPickerButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  final double size;

  const ColorPickerButton({
    required this.color,
    required this.onTap,
    this.size = 60,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.palette,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
