import 'package:flutter/material.dart';
enum TimeOfDayType {
  dawn,
  morning,
  afternoon,
  evening,
  night,
}

class WallpaperTime {
  static TimeOfDayType getCurrentTime() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 8) return TimeOfDayType.dawn;
    if (hour >= 8 && hour < 12) return TimeOfDayType.morning;
    if (hour >= 12 && hour < 17) return TimeOfDayType.afternoon;
    if (hour >= 17 && hour < 21) return TimeOfDayType.evening;
    return TimeOfDayType.night;
  }

  static List<Color> getColorsForTime(TimeOfDayType time) {
    switch (time) {
      case TimeOfDayType.dawn:
        return [const Color(0xFFFF9A9E), const Color(0xFFFAD0C4)];
      case TimeOfDayType.morning:
        return [const Color(0xFFA8E6CF), const Color(0xFFD4EDDA)];
      case TimeOfDayType.afternoon:
        return [const Color(0xFFFFD93D), const Color(0xFFFF6B6B)];
      case TimeOfDayType.evening:
        return [const Color(0xFF6C5CE7), const Color(0xFFFF9A9E)];
      case TimeOfDayType.night:
        return [const Color(0xFF0F0C29), const Color(0xFF302B63)];
    }
  }

  static String getTimeName(TimeOfDayType time) {
    switch (time) {
      case TimeOfDayType.dawn:
        return 'Рассвет';
      case TimeOfDayType.morning:
        return 'Утро';
      case TimeOfDayType.afternoon:
        return 'День';
      case TimeOfDayType.evening:
        return 'Вечер';
      case TimeOfDayType.night:
        return 'Ночь';
    }
  }
}