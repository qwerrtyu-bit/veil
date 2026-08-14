import 'dart:convert';
import 'package:flutter/material.dart';
import 'plugin_manifest.dart';
import 'plugin_api.dart';

class PluginSandbox {
  final Map<String, dynamic> _loadedPlugins = {};
  final Map<String, bool> _permissions = {};
  final PluginAPI _api = PluginAPI();

  // ============================================================
  // ЗАГРУЗКА ПЛАГИНА
  // ============================================================

  Future<void> loadPlugin(PluginManifest manifest) async {
    // Проверяем разрешения
    final neededPermissions = manifest.permissions;
    for (final perm in neededPermissions) {
      if (!_api.hasPermission(perm)) {
        throw Exception('Недостаточно разрешений: $perm');
      }
    }

    // Загружаем плагин (имитация)
    // В реальности здесь будет загрузка кода плагина
    _loadedPlugins[manifest.id] = {
      'manifest': manifest,
      'state': {},
      'loadedAt': DateTime.now(),
    };

    // Вызываем инициализацию плагина
    await _api.onPluginLoad(manifest.id);
  }

  // ============================================================
  // ВЫГРУЗКА ПЛАГИНА
  // ============================================================

  Future<void> unloadPlugin(String pluginId) async {
    if (_loadedPlugins.containsKey(pluginId)) {
      await _api.onPluginUnload(pluginId);
      _loadedPlugins.remove(pluginId);
    }
  }

  // ============================================================
  // ВЫПОЛНЕНИЕ
  // ============================================================

  Future<dynamic> execute(String pluginId, String method, Map<String, dynamic> params) async {
    if (!_loadedPlugins.containsKey(pluginId)) {
      throw Exception('Плагин не загружен');
    }

    // Проверяем разрешение на выполнение метода
    final manifest = _loadedPlugins[pluginId]['manifest'] as PluginManifest;
    if (!_api.hasMethodPermission(pluginId, method)) {
      throw Exception('Метод $method запрещён для этого плагина');
    }

    // Выполняем метод через API
    return await _api.callMethod(pluginId, method, params);
  }
}