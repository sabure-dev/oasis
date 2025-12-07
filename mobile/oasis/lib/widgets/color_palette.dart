import 'package:flutter/material.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorSelected;

  const ColorPickerDialog({
    required this.initialColor,
    required this.onColorSelected,
    super.key,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color selectedColor;
  late HSVColor hsvColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
    hsvColor = HSVColor.fromColor(selectedColor);
  }

  void _updateColor(HSVColor newHsv) {
    setState(() {
      hsvColor = newHsv;
      selectedColor = newHsv.toColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pick Color',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            // Color gradient picker
            SizedBox(
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: GestureDetector(
                  onPanDown: (details) {
                    _updateColorFromPosition(details.localPosition);
                  },
                  onPanUpdate: (details) {
                    _updateColorFromPosition(details.localPosition);
                  },
                  child: CustomPaint(
                    painter: ColorGradientPainter(hsvColor),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Hue slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hue', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 8,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                  ),
                  child: Slider(
                    value: hsvColor.hue,
                    onChanged: (value) {
                      _updateColor(hsvColor.withHue(value));
                    },
                    min: 0,
                    max: 360,
                    activeColor: HSVColor.fromAHSV(1, hsvColor.hue, 1, 1).toColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Color preview
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onColorSelected(selectedColor);
                      Navigator.pop(context);
                    },
                    child: const Text('Select'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateColorFromPosition(Offset position) {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    // Примерно рассчитываем позицию в picker'е (нужна корректировка для точного расчета)
    final saturation = (position.dx / size.width).clamp(0.0, 1.0);
    final brightness = 1 - (position.dy / size.height).clamp(0.0, 1.0);

    _updateColor(
      hsvColor.withSaturation(saturation).withValue(brightness),
    );
  }
}

class ColorGradientPainter extends CustomPainter {
  final HSVColor hsvColor;

  ColorGradientPainter(this.hsvColor);

  @override
  void paint(Canvas canvas, Size size) {
    // Рисуем градиент от белого (верхний левый) к чистому цвету (верхний правый)
    // и к черному (нижний)

    for (int y = 0; y < size.height.toInt(); y++) {
      for (int x = 0; x < size.width.toInt(); x++) {
        final saturation = x / size.width;
        final brightness = 1 - (y / size.height);

        final color = hsvColor
            .withSaturation(saturation)
            .withValue(brightness)
            .toColor();

        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ColorGradientPainter oldDelegate) {
    return oldDelegate.hsvColor != hsvColor;
  }
}