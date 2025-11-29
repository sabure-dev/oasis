import 'package:flutter/material.dart';

class GradientPreview extends StatelessWidget {
  final Color startColor;
  final Color endColor;
  final double height;

  const GradientPreview({
    required this.startColor,
    required this.endColor,
    this.height = 200,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: startColor.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}
