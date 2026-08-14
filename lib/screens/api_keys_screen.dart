import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../services/api_key_service.dart';
import '../data/identity_service.dart';
import '../models/api_key.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_model.dart';

class ApiKeysScreen extends ConsumerStatefulWidget {
  const ApiKeysScreen({super.key});

  @override
  ConsumerState<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends ConsumerState<ApiKeysScreen> {
  final _apiKeyService = ApiKeyService();
  List<ApiKey> _keys = [];
  bool _isLoading = true;
  bool _hasDevAccess = false;
  String? _userId;

  final List<Map<String, String>> _permissionOptions = [
    {'value': 'read', 'label': 'Чтение', 'description': 'Чтение баланса, транзакций, сообщений'},
    {'value': 'write', 'label': 'Запись', 'description': 'Отправка сообщений, создание карт'},
    {'value': 'transfer', 'label': 'Переводы', 'description': 'Перевод средств между пользователями'},
    {'value': 'delete', 'label': 'Удаление', 'description': 'Удаление сообщений и чатов'},
    {'value': 'giftcard', 'label': 'Подарочные карты', 'description': 'Создание и активация карт'},
    {'value': 'backup', 'label': 'Бэкапы', 'description': 'Создание и восстановление бэкапов'},
    {'value': 'plugin', 'label': 'Плагины', 'description': 'Установка и удаление плагинов'},
    {'value': 'settings', 'label': 'Настройки', 'description': 'Изменение настроек пользователя'},
    {'value': 'admin', 'label': 'Администратор', 'description': 'Полный доступ ко всем функциям'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final identityService = IdentityService();
    final userId = await identityService.getPublicKey() ?? 'unknown';
    _userId = userId;

    final currentTier = ref.read(subscriptionProvider);
    final plan = SubscriptionPlan.getPlan(currentTier);
    _hasDevAccess = plan.hasApiAccess;

    if (_hasDevAccess) {
      _keys = _apiKeyService.getKeysByUser(userId);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _createKey() async {
    final nameController = TextEditingController();
    List<String> selectedPermissions = ['read'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Создать API ключ'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Введите название ключа', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Мой ключ',
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Разрешения:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView(
                      shrinkWrap: true,
                      children: _permissionOptions.map((perm) {
                        final isSelected = selectedPermissions.contains(perm['value']);
                        return CheckboxListTile(
                          title: Text(
                            perm['label']!,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            perm['description']!,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          value: isSelected,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedPermissions.add(perm['value']!);
                              } else {
                                selectedPermissions.remove(perm['value']);
                              }
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Введите название ключа'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (selectedPermissions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Выберите хотя бы одно разрешение'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final key = await _apiKeyService.createKey(
                    name: name,
                    userId: _userId!,
                    permissions: selectedPermissions,
                    expiresIn: const Duration(days: 365),
                  );

                  Navigator.pop(ctx);
                  await _loadData();
                  _showKeyDialog(key.key);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('API ключ создан!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Создать'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showKeyDialog(String key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('API ключ создан'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Сохраните этот ключ. Он больше не будет отображаться.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0C29),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6C5CE7)),
              ),
              child: SelectableText(
                key,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: key));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ключ скопирован'),
                  backgroundColor: Color(0xFF6C5CE7),
                ),
              );
            },
            child: const Text('Копировать'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _revokeKey(String keyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отозвать ключ?'),
        content: const Text('Ключ будет отозван и перестанет работать.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Отозвать', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiKeyService.revokeKey(keyId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ключ отозван'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('API ключи'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        actions: [
          if (_hasDevAccess)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createKey,
              tooltip: 'Создать ключ',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasDevAccess
              ? _buildKeysList(theme)
              : _buildNoAccess(theme),
    );
  }

  Widget _buildNoAccess(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Доступ к API',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'API доступен только на тарифах Dev и Pro',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/subscription'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
            ),
            child: const Text('Обновить тариф'),
          ),
        ],
      ),
    );
  }

  Widget _buildKeysList(ThemeData theme) {
    if (_keys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.key_off,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет API ключей',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте первый ключ для доступа к API',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _keys.length,
      itemBuilder: (context, index) {
        final key = _keys[index];
        final isActive = key.isActive &&
            (key.expiresAt == null || key.expiresAt!.isAfter(DateTime.now()));

        return Card(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isActive
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isActive ? Icons.key : Icons.key_off,
              color: isActive ? Colors.green : Colors.red,
            ),
            title: Text(
              key.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Создан: ${_formatDate(key.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                if (key.expiresAt != null)
                  Text(
                    'Истекает: ${_formatDate(key.expiresAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.orange : Colors.red,
                    ),
                  ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: key.permissions.map((perm) {
                    Color permColor;
                    String label;
                    switch (perm) {
                      case 'read':
                        permColor = Colors.blue;
                        label = 'Чтение';
                        break;
                      case 'write':
                        permColor = Colors.green;
                        label = 'Запись';
                        break;
                      case 'delete':
                        permColor = Colors.red;
                        label = 'Удаление';
                        break;
                      case 'transfer':
                        permColor = Colors.orange;
                        label = 'Переводы';
                        break;
                      case 'giftcard':
                        permColor = const Color(0xFF6C5CE7);
                        label = 'Карты';
                        break;
                      case 'backup':
                        permColor = const Color(0xFF10B981);
                        label = 'Бэкапы';
                        break;
                      case 'plugin':
                        permColor = const Color(0xFFF59E0B);
                        label = 'Плагины';
                        break;
                      case 'settings':
                        permColor = Colors.cyan;
                        label = 'Настройки';
                        break;
                      case 'admin':
                        permColor = Colors.purple;
                        label = 'Админ';
                        break;
                      default:
                        permColor = Colors.grey;
                        label = perm;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: permColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: permColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            trailing: isActive
                ? IconButton(
                    icon: const Icon(Icons.block, color: Colors.orange),
                    onPressed: () => _revokeKey(key.id),
                    tooltip: 'Отозвать ключ',
                  )
                : const Icon(Icons.check_circle, color: Colors.grey),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}