import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:oasis/models/gradient_theme.dart';

class ThemeProvider extends ChangeNotifier {
  final Isar isar;
  late GradientTheme _currentTheme;
  final List<GradientTheme> _presetThemes = [];
  final List<GradientTheme> _customThemes = [];

  ThemeProvider({required this.isar}) {
    _initializePresets();
  }

  void _initializePresets() {
    _presetThemes.addAll([
      GradientTheme(
        startColor: const Color.fromARGB(255, 155, 182, 214),
        endColor: const Color.fromARGB(255, 121, 163, 214),
        name: 'Ocean Blue',
        isPreset: true,
      ),
      GradientTheme(
        startColor: const Color.fromARGB(255, 255, 107, 107),
        endColor: const Color.fromARGB(255, 255, 193, 7),
        name: 'Sunset',
        isPreset: true,
      ),
      GradientTheme(
        startColor: const Color.fromARGB(255, 108, 92, 231),
        endColor: const Color.fromARGB(255, 162, 155, 254),
        name: 'Purple Dream',
        isPreset: true,
      ),
      GradientTheme(
        startColor: const Color.fromARGB(255, 46, 204, 113),
        endColor: const Color.fromARGB(255, 52, 152, 219),
        name: 'Forest',
        isPreset: true,
      ),
    ]);
    _currentTheme = _presetThemes[0];
  }

  Future<void> initialize() async {
    await _loadCustomThemes();
    await _loadCurrentTheme();
    notifyListeners();
  }

  Future<void> _loadCustomThemes() async {
    final customModels = await isar.gradientThemeModels
        .filter()
        .isPresetEqualTo(false)
        .findAll();
    _customThemes.clear();
    for (final model in customModels) {
      _customThemes.add(GradientTheme.fromModel(model));
    }
  }

  Future<void> _loadCurrentTheme() async {
    final currentModel = await isar.gradientThemeModels
        .filter()
        .isCurrentEqualTo(true)
        .findFirst();

    if (currentModel != null) {
      _currentTheme = GradientTheme.fromModel(currentModel);
    } else {
      _currentTheme = _presetThemes[0];
    }
  }

  GradientTheme get currentTheme => _currentTheme;

  List<GradientTheme> get allThemes => [..._presetThemes, ..._customThemes];

  List<GradientTheme> get presetThemes => _presetThemes;

  List<GradientTheme> get customThemes => _customThemes;

  Future<void> setTheme(GradientTheme theme) async {
    _currentTheme = theme;

    // Обновляем флаг isCurrent для всех тем
    await isar.writeTxn(() async {
      final allModels = await isar.gradientThemeModels.where().findAll();
      for (final model in allModels) {
        model.isCurrent = false;
      }
      await isar.gradientThemeModels.putAll(allModels);

      // Если это сохраненная тема, обновляем в БД
      if (theme.id != null) {
        final themeModel = theme.toModel()..isCurrent = true;
        await isar.gradientThemeModels.put(themeModel);
      }
    });

    notifyListeners();
  }

  Future<void> addCustomTheme(GradientTheme theme) async {
    final newTheme = theme.copyWith(isPreset: false);
    final model = newTheme.toModel();

    await isar.writeTxn(() async {
      await isar.gradientThemeModels.put(model);
    });

    // Перезагружаем custom темы
    await _loadCustomThemes();
    notifyListeners();
  }

  Future<void> removeCustomTheme(int index) async {
    if (index < _customThemes.length) {
      final theme = _customThemes[index];

      if (theme.id != null) {
        await isar.writeTxn(() async {
          await isar.gradientThemeModels.delete(theme.id!);
        });
      }

      _customThemes.removeAt(index);
      notifyListeners();
    }
  }
}
