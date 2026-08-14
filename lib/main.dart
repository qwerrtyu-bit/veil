import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

// ============================================================
// ПЛАГИНЫ
// ============================================================
import 'plugins/plugin_manager.dart';
import 'plugins/plugin_api.dart';
import 'plugins/veil_plugins.dart';   // 👈 ВСЕ ПЛАГИНЫ В ОДНОМ ФАЙЛЕ

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // FIREBASE
  // ============================================================
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('🔥 Firebase инициализирован');
  } catch (e) {
    print('❌ Ошибка Firebase: $e');
  }

  // ============================================================
  // УВЕДОМЛЕНИЯ
  // ============================================================
  try {
    await NotificationService().init();
  } catch (e) {
    print('❌ Ошибка уведомлений: $e');
  }

  // ============================================================
  // HIVE
  // ============================================================
  try { await Hive.initFlutter(); } catch (_) {}
  try { await Hive.openBox('contacts'); } catch (_) {}
  try { await Hive.openBox('messages'); } catch (_) {}
  try { await Hive.openBox('settings'); } catch (_) {}
  try { await Hive.openBox('secure'); } catch (_) {}
  try { await Hive.openBox('wallet'); } catch (_) {}
  try { await Hive.openBox('gift_requests'); } catch (_) {}
  try { await Hive.openBox('api_keys'); } catch (_) {}
  try { await Hive.openBox('wallpapers'); } catch (_) {}
  try { await Hive.openBox('plugins'); } catch (_) {}
  try { await Hive.openBox('plugin_data'); } catch (_) {}
  try { await Hive.openBox('backups'); } catch (_) {}
  try { await Hive.openBox('bots'); } catch (_) {}

  // ============================================================
  // 🔌 ИНИЦИАЛИЗАЦИЯ ПЛАГИНОВ
  // ============================================================

  final pluginAPI = PluginAPI();
  
  // Регистрируем ВСЕ плагины (в одном вызове)
  VeilPluginRegistry.registerAll(pluginAPI);

  final pluginManager = PluginManager();
  await pluginManager.loadInstalledPlugins();

  print('✅ Все плагины загружены');

  // ============================================================
  // ЗАПУСК ПРИЛОЖЕНИЯ
  // ============================================================
  runApp(
    const ProviderScope(
      child: VeilApp(),
    ),
  );
}