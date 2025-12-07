import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/providers/theme_provider.dart';
import 'package:oasis/screens/theme_customizer_screen.dart';
import 'package:oasis/widgets/gradient_preview.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

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
            title: const Text('Themes', style: TextStyle(color: Colors.white)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(gradient: gradient),
            child: ListView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 100, bottom: 100),
              children: [
                _buildThemeSection(
                  context,
                  'Presets',
                  themeProvider.presetThemes,
                  themeProvider,
                  isPreset: true,
                ),
                const SizedBox(height: 24),
                if (themeProvider.customThemes.isNotEmpty)
                  _buildThemeSection(
                    context,
                    'Custom Themes',
                    themeProvider.customThemes,
                    themeProvider,
                    isPreset: false,
                  ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ThemeCustomizerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Custom Theme'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    String title,
    List themes,
    dynamic themeProvider,
    {required bool isPreset}
  ) {
    if (themes.isEmpty && !isPreset) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          themes.length,
          (index) {
            final theme = themes[index];
            final isSelected =
                themeProvider.currentTheme == theme;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  themeProvider.setTheme(theme);
                  Navigator.pop(context);
                },
                onLongPress: !isPreset
                    ? () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Theme?'),
                            content: Text(
                              'Are you sure you want to delete "${theme.name}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  themeProvider
                                      .removeCustomTheme(index);
                                  Navigator.pop(context);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
                child: Stack(
                  children: [
                    GradientPreview(
                      startColor: theme.startColor,
                      endColor: theme.endColor,
                      height: 80,
                    ),
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          theme.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}