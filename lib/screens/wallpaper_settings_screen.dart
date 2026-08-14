import 'package:flutter/material.dart';
import '../models/wallpaper_time.dart';

class WallpaperSettingsScreen extends StatefulWidget {
  const WallpaperSettingsScreen({super.key});

  @override
  State<WallpaperSettingsScreen> createState() =>
      _WallpaperSettingsScreenState();
}

class _WallpaperSettingsScreenState extends State<WallpaperSettingsScreen> {
  TimeOfDayType _selectedTime = WallpaperTime.getCurrentTime();

  final Map<TimeOfDayType, String> _timeNames = {
    TimeOfDayType.dawn: '🌅 Рассвет',
    TimeOfDayType.morning: '☀️ Утро',
    TimeOfDayType.afternoon: '🌤️ День',
    TimeOfDayType.evening: '🌇 Вечер',
    TimeOfDayType.night: '🌙 Ночь',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Динамические обои'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Выберите время суток для обоев',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ..._timeNames.entries.map((entry) {
            final isSelected = _selectedTime == entry.key;
            final colors = WallpaperTime.getColorsForTime(entry.key);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: isSelected ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF6C5CE7)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                title: Text(entry.value),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFF6C5CE7))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedTime = entry.key;
                  });
                  // Сохраняем настройку
                  // TODO: сохранить в Hive
                },
              ),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Применить настройки
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }
}