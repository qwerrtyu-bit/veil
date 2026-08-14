import 'package:hive_flutter/hive_flutter.dart';

class PluginManager {
  static final PluginManager _instance = PluginManager._internal();
  factory PluginManager() => _instance;
  PluginManager._internal();

  final Box _pluginsBox = Hive.box('plugins');
  final Map<String, bool> _loadedPlugins = {};

  // ============================================================
  // ЗАГРУЗКА УСТАНОВЛЕННЫХ ПЛАГИНОВ
  // ============================================================

  Future<void> loadInstalledPlugins() async {
    final installed = _pluginsBox.get('installed', defaultValue: <String>[]);
    for (final id in installed) {
      _loadedPlugins[id] = true;
      print('✅ Плагин загружен: $id');
    }
  }

  // ============================================================
  // УСТАНОВКА ПЛАГИНА
  // ============================================================

  Future<bool> installPlugin(String id) async {
    final installed = _pluginsBox.get('installed', defaultValue: <String>[]);
    if (installed.contains(id)) return false;
    installed.add(id);
    await _pluginsBox.put('installed', installed);
    _loadedPlugins[id] = true;
    print('✅ Плагин установлен: $id');
    return true;
  }

  // ============================================================
  // УДАЛЕНИЕ ПЛАГИНА
  // ============================================================

  Future<void> uninstallPlugin(String id) async {
    final installed = _pluginsBox.get('installed', defaultValue: <String>[]);
    installed.remove(id);
    await _pluginsBox.put('installed', installed);
    _loadedPlugins.remove(id);
    print('🗑️ Плагин удалён: $id');
  }

  // ============================================================
  // ПРОВЕРКА
  // ============================================================

  List<String> getInstalledPlugins() {
    return List<String>.from(_pluginsBox.get('installed', defaultValue: <String>[]));
  }

  bool isPluginInstalled(String id) {
    final installed = _pluginsBox.get('installed', defaultValue: <String>[]);
    return installed.contains(id);
  }

  bool isPluginLoaded(String id) {
    return _loadedPlugins.containsKey(id) && _loadedPlugins[id] == true;
  }
}