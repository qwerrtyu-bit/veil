import 'dart:io'; // <-- ДОБАВЛЕНО
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../services/backup_service.dart';
import '../l10n/app_localizations.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _backupService = BackupService();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createBackup() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _statusMessage = 'Введите пароль для шифрования бэкапа';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final filePath = await _backupService.exportBackup(password);
      
      if (filePath != null) {
        final fileName = filePath.split(Platform.pathSeparator).last;
        setState(() {
          _statusMessage = '✅ Бэкап создан: $fileName';
          _isSuccess = true;
        });
      } else {
        setState(() {
          _statusMessage = '❌ Создание бэкапа отменено';
          _isSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка: $e';
        _isSuccess = false;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _restoreBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['veilbackup'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _statusMessage = '❌ Восстановление отменено';
          _isSuccess = false;
          _isLoading = false;
        });
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        setState(() {
          _statusMessage = '❌ Не удалось прочитать файл';
          _isSuccess = false;
          _isLoading = false;
        });
        return;
      }

      final password = await _showPasswordDialog(context);
      if (password == null) {
        setState(() {
          _statusMessage = '❌ Восстановление отменено';
          _isSuccess = false;
          _isLoading = false;
        });
        return;
      }

      final success = await _backupService.importBackup(file.path!, password);
      
      setState(() {
        _statusMessage = success 
            ? '✅ Бэкап восстановлен! Перезапустите приложение.' 
            : '❌ Ошибка восстановления. Проверьте пароль.';
        _isSuccess = success;
        _isLoading = false;
      });

      if (success) {
        _showRestartDialog(context);
      }

    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка: $e';
        _isSuccess = false;
        _isLoading = false;
      });
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Пароль от бэкапа'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Введите пароль, который использовали при создании бэкапа.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Пароль',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Восстановить'),
          ),
        ],
      ),
    );
  }

  void _showRestartDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('✅ Восстановление завершено'),
        content: const Text(
          'Данные восстановлены. Перезапустите приложение, чтобы изменения вступили в силу.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/chats');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Резервное копирование'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Бэкап содержит все ваши данные, включая приватные ключи. Храните файл в надёжном месте и никому не показывайте.',
                      style: TextStyle(color: Colors.orange[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Пароль для шифрования',
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Придумайте надёжный пароль',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Этот пароль понадобится для восстановления данных из бэкапа.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createBackup,
                    icon: const Icon(Icons.download),
                    label: const Text('Создать бэкап'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _restoreBackup,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Восстановить'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6C5CE7)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess 
                      ? Colors.green.withOpacity(0.05) 
                      : Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSuccess ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green : Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Подождите...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}