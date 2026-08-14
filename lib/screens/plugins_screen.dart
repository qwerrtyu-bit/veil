import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';

import '../plugins/plugin_manager.dart';
import '../plugins/plugin_loader.dart';
import '../plugins/veil_plugins.dart';
import '../l10n/app_localizations.dart';

class PluginsScreen extends ConsumerStatefulWidget {
  const PluginsScreen({super.key});

  @override
  ConsumerState<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends ConsumerState<PluginsScreen> {
  final List<Map<String, dynamic>> _plugins = [];
  final List<String> _installed = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _availablePlugins = [
    {
      'id': VeilTranslator.id,
      'name': VeilTranslator.name,
      'author': VeilTranslator.author,
      'version': VeilTranslator.version,
      'description': 'Перевод сообщений на любой язык',
      'type': 'chat',
      'price': 'Бесплатно',
      'icon': '🌐',
      'status': 'approved',
    },
    {
      'id': VeilReminder.id,
      'name': VeilReminder.name,
      'author': VeilReminder.author,
      'version': VeilReminder.version,
      'description': 'Напоминания о важных сообщениях',
      'type': 'chat',
      'price': 'Бесплатно',
      'icon': '⏰',
      'status': 'approved',
    },
    {
      'id': VeilStats.id,
      'name': VeilStats.name,
      'author': VeilStats.author,
      'version': VeilStats.version,
      'description': 'Статистика чата: активность, слова, участники',
      'type': 'analytics',
      'price': 'Бесплатно',
      'icon': '📊',
      'status': 'approved',
    },
    {
      'id': VeilScheduler.id,
      'name': VeilScheduler.name,
      'author': VeilScheduler.author,
      'version': VeilScheduler.version,
      'description': 'Отложенная отправка сообщений',
      'type': 'chat',
      'price': 'Бесплатно',
      'icon': '📅',
      'status': 'approved',
    },
    {
      'id': VeilSafeBackup.id,
      'name': VeilSafeBackup.name,
      'author': VeilSafeBackup.author,
      'version': VeilSafeBackup.version,
      'description': 'Автоматический бэкап чатов',
      'type': 'security',
      'price': 'Бесплатно',
      'icon': '💾',
      'status': 'approved',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() => _isLoading = true);
    
    final manager = PluginManager();
    _installed.clear();
    _installed.addAll(manager.getInstalledPlugins());
    
    _plugins.clear();
    _plugins.addAll(_availablePlugins);
    
    setState(() => _isLoading = false);
  }

  Future<void> _installPlugin(String id) async {
    final manager = PluginManager();
    
    if (manager.isPluginInstalled(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Плагин уже установлен'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await manager.installPlugin(id);
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Плагин установлен!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uninstallPlugin(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить плагин?'),
        content: const Text('Плагин будет удалён. Это действие можно отменить повторной установкой.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final manager = PluginManager();
      await manager.uninstallPlugin(id);
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Плагин удалён'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _installFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['veilP'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) return;

      final content = utf8.decode(file.bytes!);
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      final pluginId = data['id'] as String?;
      if (pluginId == null) {
        throw Exception('Не найден ID плагина');
      }

      final manager = PluginManager();
      await manager.installPlugin(pluginId);
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Плагин "${data['name'] ?? pluginId}" установлен!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(l10n.plugins),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open),
            onPressed: _installFromFile,
            tooltip: 'Установить из .veilP',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _plugins.length,
              itemBuilder: (context, index) {
                final plugin = _plugins[index];
                final isInstalled = _installed.contains(plugin['id']);
                final isActive = isInstalled;

                return Card(
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isInstalled 
                          ? const Color(0xFF10B981).withOpacity(0.3) 
                          : Colors.transparent,
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              plugin['icon'] ?? '🧩',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    plugin['name'] ?? 'Плагин',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isInstalled)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isActive 
                                            ? const Color(0xFF10B981).withOpacity(0.15)
                                            : Colors.orange.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        isActive ? 'Активен' : 'Отключён',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isActive 
                                              ? const Color(0xFF10B981)
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                plugin['description'] ?? '',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '👤 ${plugin['author']}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '📦 ${plugin['version']}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (plugin['price'] != 'Бесплатно') ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      '💰 ${plugin['price']}',
                                      style: TextStyle(
                                        color: const Color(0xFF6C5CE7),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isInstalled)
                          ElevatedButton(
                            onPressed: () => _installPlugin(plugin['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Установить',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          )
                        else
                          OutlinedButton(
                            onPressed: () => _uninstallPlugin(plugin['id']),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Удалить',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}