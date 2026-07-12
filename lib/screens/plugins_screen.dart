// ========== lib/screens/plugins_screen.dart ==========
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../data/plugin_scanner.dart';

class PluginsScreen extends ConsumerStatefulWidget {
  const PluginsScreen({super.key});

  @override
  ConsumerState<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends ConsumerState<PluginsScreen> {
  final List<Map<String, dynamic>> _plugins = [];

  @override
  void initState() {
    super.initState();
    _loadPlugins();
    _loadFromRegistry();
  }

  void _loadPlugins() {
    final box = Hive.box('messages');
    final raw = box.get('plugins', defaultValue: <Map<String, dynamic>>[]);
    _plugins.clear();
    if (raw is List) {
      _plugins.addAll(raw.where((item) => item is Map).map((item) => Map<String, dynamic>.from(item as Map)));
    }
    if (_plugins.isEmpty) {
      _plugins.addAll([
        {
          'id': '1', 'name': 'Тёмная тема Pro', 'author': 'void', 'type': 'theme',
          'price': 'Бесплатно', 'status': 'approved', 'description': 'Расширенная тёмная тема с настройками цветов',
        },
        {
          'id': '2', 'name': 'Антиспам фильтр', 'author': '0xTima', 'type': 'filter',
          'price': '299 ₽', 'status': 'approved', 'description': 'Автоматическое удаление спам-сообщений',
        },
        {
          'id': '3', 'name': 'Экспорт в PDF', 'author': 'user123', 'type': 'export',
          'price': 'Бесплатно', 'status': 'pending', 'description': 'Выгрузка чатов в PDF формат',
        },
      ]);
      Hive.box('messages').put('plugins', _plugins);
    }
    setState(() {});
  }

  Future<void> _loadFromRegistry() async {
    try {
      final response = await http.get(Uri.parse('https://localhost:8443/plugins'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final registryPlugins = data['plugins'] as List;
        setState(() {
          for (final p in registryPlugins) {
            if (p is Map) {
              final exists = _plugins.any((lp) => lp['id'] == p['id']);
              if (!exists) {
                _plugins.add(Map<String, dynamic>.from(p));
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  void _installFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;
    if (!file.name.endsWith('.veilP')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите файл .veilP'), backgroundColor: Colors.red),
      );
      return;
    }

    final code = utf8.decode(file.bytes!);

    final scanner = PluginScanner();
    final scanResult = scanner.scan(code);

    if (!scanResult.safe) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('⚠️ Опасный плагин'),
          content: Text(scanResult.message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ],
        ),
      );
      return;
    }

    final box = Hive.box('messages');
    final raw = box.get('plugins');
    List<Map<String, dynamic>> pluginsList = [];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) pluginsList.add(Map<String, dynamic>.from(item));
      }
    }

    pluginsList.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': file.name.replaceAll('.veilP', ''),
      'author': 'Локальный',
      'type': 'custom',
      'price': 'Бесплатно',
      'status': 'approved',
      'description': 'Установлен из файла',
    });

    box.put('plugins', pluginsList);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Плагин установлен!'), backgroundColor: Color(0xFF10B981)),
    );

    _loadPlugins();
  }

  void _submitPlugin() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A26),
        title: const Text('Отправить плагин', style: TextStyle(color: Color(0xFFE0E0E0))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Отправьте ваш .veilP файл на проверку:\n\n📧 veil.plugins@proton.me\n📱 @VeilMessenger\n\nПроверка занимает 1-2 дня.',
              style: TextStyle(color: Color(0xFF888899)),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Разработчик Veil не несёт ответственности за сторонние плагины. Каждый плагин проходит обязательную проверку антивирусом. Установка плагина означает согласие с политикой конфиденциальности.',
              style: TextStyle(color: Colors.orange, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final free = _plugins.where((p) => p['price'] == 'Бесплатно').toList();
    final paid = _plugins.where((p) => p['price'] != 'Бесплатно').toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Плагины (.veilP)'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats')),
        actions: [
          IconButton(icon: const Icon(Icons.file_open), onPressed: _installFromFile, tooltip: 'Установить из файла'),
          IconButton(icon: const Icon(Icons.add), onPressed: _submitPlugin),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (free.isNotEmpty) ...[
            _buildSection('Бесплатные'),
            ...free.map((p) => _buildPluginCard(p)),
          ],
          if (paid.isNotEmpty) ...[
            _buildSection('Платные'),
            ...paid.map((p) => _buildPluginCard(p)),
          ],
          if (_plugins.isEmpty)
            const Center(child: Text('Нет плагинов', style: TextStyle(color: Color(0xFF888899)))),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title.toUpperCase(),
          style: const TextStyle(color: Color(0xFF888899), fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildPluginCard(Map<String, dynamic> plugin) {
    final isPending = plugin['status'] == 'pending';
    return Card(
      color: const Color(0xFF1A1A26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          plugin['type'] == 'theme' ? Icons.palette : plugin['type'] == 'filter' ? Icons.filter_alt : Icons.download,
          color: isPending ? Colors.orange : const Color(0xFF4ADE80),
        ),
        title: Text(plugin['name'] as String, style: const TextStyle(color: Color(0xFFE0E0E0))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plugin['description'] as String, style: const TextStyle(color: Color(0xFF888899), fontSize: 12)),
            Row(children: [
              Text('от ${plugin['author']}', style: const TextStyle(color: Color(0xFF888899), fontSize: 11)),
              const SizedBox(width: 8),
              Text(plugin['price'] as String, style: TextStyle(color: const Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.w600)),
              if (isPending) ...[
                const SizedBox(width: 8),
                const Text('На проверке', style: TextStyle(color: Colors.orange, fontSize: 11)),
              ],
            ]),
          ],
        ),
        onTap: () => context.go('/plugin-detail', extra: plugin),
      ),
    );
  }
}