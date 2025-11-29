import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

part 'gradient_theme.g.dart';

@collection
class GradientThemeModel {
  Id? id;

  late int startColorValue;
  late int endColorValue;
  late String name;
  late bool isPreset;
  late bool isCurrent;

  GradientThemeModel({
    this.id,
    required this.startColorValue,
    required this.endColorValue,
    required this.name,
    this.isPreset = false,
    this.isCurrent = false,
  });

  Map<String, dynamic> toJson() => {
        'startColor': startColorValue,
        'endColor': endColorValue,
        'name': name,
        'isPreset': isPreset,
        'isCurrent': isCurrent,
      };
}

// Класс для работы с темой (используется в провайдере)
class GradientTheme {
  final int? id;
  final Color startColor;
  final Color endColor;
  final String name;
  final bool isPreset;
  final bool isCurrent;

  GradientTheme({
    this.id,
    required this.startColor,
    required this.endColor,
    required this.name,
    this.isPreset = false,
    this.isCurrent = false,
  });

  GradientThemeModel toModel() {
    return GradientThemeModel(
      id: id,
      startColorValue: startColor.value,
      endColorValue: endColor.value,
      name: name,
      isPreset: isPreset,
      isCurrent: isCurrent,
    );
  }

  factory GradientTheme.fromModel(GradientThemeModel model) {
    return GradientTheme(
      id: model.id,
      startColor: Color(model.startColorValue),
      endColor: Color(model.endColorValue),
      name: model.name,
      isPreset: model.isPreset,
      isCurrent: model.isCurrent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradientTheme &&
          runtimeType == other.runtimeType &&
          startColor == other.startColor &&
          endColor == other.endColor &&
          name == other.name;

  @override
  int get hashCode => startColor.hashCode ^ endColor.hashCode ^ name.hashCode;

  GradientTheme copyWith({
    int? id,
    Color? startColor,
    Color? endColor,
    String? name,
    bool? isPreset,
    bool? isCurrent,
  }) {
    return GradientTheme(
      id: id ?? this.id,
      startColor: startColor ?? this.startColor,
      endColor: endColor ?? this.endColor,
      name: name ?? this.name,
      isPreset: isPreset ?? this.isPreset,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}
