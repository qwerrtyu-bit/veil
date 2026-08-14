import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/role_model.dart';
import '../services/role_service.dart';
import '../services/admin_service.dart';
import '../l10n/app_localizations.dart';

class RoleManagementScreen extends ConsumerStatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  ConsumerState<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends ConsumerState<RoleManagementScreen> {
  final _roleService = RoleService();
  final _adminService = AdminService();
  final _keyController = TextEditingController();
  Map<String, UserRole> _roles = {};
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final isAdmin = await _adminService.isAdmin();
    if (!isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Доступ запрещён. Только для администраторов.'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/settings');
      }
      return;
    }

    setState(() {
      _isAdmin = true;
      _roles = _roleService.getAllRoles();
      _isLoading = false;
    });
  }

  Future<void> _addRole() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите публичный ключ'), backgroundColor: Colors.red),
      );
      return;
    }

    UserRole? selectedRole;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Выберите роль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            if (role == UserRole.user) return const SizedBox.shrink();
            return RadioListTile<UserRole>(
              title: Row(
                children: [
                  Text(role.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(role.displayName),
                ],
              ),
              subtitle: Text(
                role.permissions.join(', '),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              value: role,
              groupValue: selectedRole,
              onChanged: (value) {
                selectedRole = value;
                Navigator.pop(ctx, value);
              },
            );
          }).toList(),
        ),
      ),
    );

    if (selectedRole == null) return;

    await _roleService.setRole(key, selectedRole!);
    setState(() {
      _roles = _roleService.getAllRoles();
      _keyController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Пользователь добавлен как ${selectedRole!.displayName}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _removeRole(String key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить роль?'),
        content: Text('Пользователь ${key.substring(0, 8)}... станет обычным пользователем.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    await _roleService.removeRole(key);
    setState(() {
      _roles = _roleService.getAllRoles();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Роль удалена'), backgroundColor: Colors.orange),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAdmin) {
      return const Scaffold(body: Center(child: Text('Доступ запрещён')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Управление ролями'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _keyController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Публичный ключ пользователя',
                        prefixIcon: Icon(Icons.key),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addRole,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                        ),
                        child: const Text('Добавить роль'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Назначенные роли', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_roles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Нет назначенных ролей', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._roles.entries.map((entry) {
                final key = entry.key;
                final role = entry.value;
                final isCofounder = role == UserRole.cofounder;
                return Card(
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: role.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(role.icon, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    title: Text(
                      key.length > 16 ? '${key.substring(0, 16)}…' : key,
                      style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 13),
                    ),
                    subtitle: Row(
                      children: [
                        Text(role.displayName),
                        if (isCofounder) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '👑',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeRole(key),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Роли: 👤 Пользователь, 🧪 Бета-тестер, 🛡️ Модератор, 👑 Соучредитель, ⚡ Администратор',
                      style: TextStyle(color: Colors.orange[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}