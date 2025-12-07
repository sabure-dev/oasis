import 'package:flutter/material.dart';
import 'package:oasis/models/gradient_theme.dart';
import 'package:oasis/providers/theme_provider.dart';
import 'package:oasis/widgets/color_palette.dart';
import 'package:oasis/widgets/color_picker_button.dart';
import 'package:oasis/widgets/gradient_preview.dart';
import 'package:provider/provider.dart';

class ThemeCustomizerScreen extends StatefulWidget {
  final GradientTheme? initialTheme;

  const ThemeCustomizerScreen({this.initialTheme, super.key});

  @override
  State<ThemeCustomizerScreen> createState() => _ThemeCustomizerScreenState();
}

class _ThemeCustomizerScreenState extends State<ThemeCustomizerScreen> {
  late Color startColor;
  late Color endColor;
  late TextEditingController nameController;
  int _selectedColorPicker = 0;

  @override
  void initState() {
    super.initState();
    final theme = widget.initialTheme ??
        Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    startColor = theme.startColor;
    endColor = theme.endColor;
    nameController = TextEditingController(text: theme.name);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _showColorPicker(int colorPicker) {
    setState(() {
      _selectedColorPicker = colorPicker;
    });
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: colorPicker == 0 ? startColor : endColor,
        onColorSelected: (color) {
          setState(() {
            if (colorPicker == 0) {
              startColor = color;
            } else {
              endColor = color;
            }
          });
        },
      ),
    );
  }

  void _saveTheme() {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a theme name')),
      );
      return;
    }

    final newTheme = GradientTheme(
      startColor: startColor,
      endColor: endColor,
      name: nameController.text,
    );

    Provider.of<ThemeProvider>(context, listen: false).addCustomTheme(newTheme);
    Provider.of<ThemeProvider>(context, listen: false).setTheme(newTheme);
    Navigator.pop(context);
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Customize Theme', style: TextStyle(color: Colors.white)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(gradient: gradient),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 100, bottom: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GradientPreview(
                    startColor: startColor,
                    endColor: endColor,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text('Start Color', style: TextStyle(color: Colors.white)),
                          const SizedBox(height: 12),
                          ColorPickerButton(
                            color: startColor,
                            onTap: () => _showColorPicker(0),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('End Color', style: TextStyle(color: Colors.white)),
                          const SizedBox(height: 12),
                          ColorPickerButton(
                            color: endColor,
                            onTap: () => _showColorPicker(1),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Theme Name',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.label),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _saveTheme,
                    icon: const Icon(Icons.save),
                    label: const Text('Save & Apply'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
