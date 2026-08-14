import 'package:flutter/material.dart';

enum WallpaperType {
  gradient,
  image,
}

class Wallpaper {
  final String id;
  final String name;
  final WallpaperType type;
  final List<Color>? colors; // для градиента
  final String? imagePath; // для фото
  final String? previewPath;

  Wallpaper({
    required this.id,
    required this.name,
    required this.type,
    this.colors,
    this.imagePath,
    this.previewPath,
  });

  /// Предустановленные градиентные обои
  static final List<Wallpaper> defaults = [
    Wallpaper(
      id: 'gradient_1',
      name: 'Ночное небо',
      type: WallpaperType.gradient,
      colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
    ),
    Wallpaper(
      id: 'gradient_2',
      name: 'Закат',
      type: WallpaperType.gradient,
      colors: [Color(0xFFF12711), Color(0xFFF5AF19)],
    ),
    Wallpaper(
      id: 'gradient_3',
      name: 'Океан',
      type: WallpaperType.gradient,
      colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)],
    ),
    Wallpaper(
      id: 'gradient_4',
      name: 'Лаванда',
      type: WallpaperType.gradient,
      colors: [Color(0xFF6C5CE7), Color(0xFFA78BFA)],
    ),
    Wallpaper(
      id: 'gradient_5',
      name: 'Лес',
      type: WallpaperType.gradient,
      colors: [Color(0xFF134E5E), Color(0xFF71B280)],
    ),
    Wallpaper(
      id: 'gradient_6',
      name: 'Космос',
      type: WallpaperType.gradient,
      colors: [Color(0xFF000000), Color(0xFF434343)],
    ),
    Wallpaper(
      id: 'gradient_7',
      name: 'Розовый закат',
      type: WallpaperType.gradient,
      colors: [Color(0xFFFF6B6B), Color(0xFFFFB8B8)],
    ),
    Wallpaper(
      id: 'gradient_8',
      name: 'Синий градиент',
      type: WallpaperType.gradient,
      colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
    ),
  ];

  /// Получить градиент для обоев
  Decoration get decoration {
    if (type == WallpaperType.gradient && colors != null && colors!.length >= 2) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: colors!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    return BoxDecoration(
      color: Colors.black,
    );
  }
}