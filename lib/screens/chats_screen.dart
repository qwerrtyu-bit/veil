import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/chat_service.dart';
import '../data/p2p_service.dart';
import '../core/constants.dart';
import '../l10n/app_localizations.dart';
import '../services/admin_service.dart';
import '../providers/websocket_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final _chatService = ChatService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final List<Map<String, dynamic>> _items = [];
  bool _isAdmin = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _checkAdmin();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final webSocket = ref.read(webSocketProvider);
    if (!webSocket.isConnected) {
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      webSocket.connect(userId);
      print('🔗 WebSocket подключён из ChatsScreen');
    } else {
      print('✅ WebSocket уже подключён');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    final adminService = AdminService();
    final isAdmin = await adminService.isAdmin();
    setState(() => _isAdmin = isAdmin);
  }
  Future<String?> _getUsername(String publicKey) async {
  try {
    final response = await http.get(
      Uri.parse('${VeilConstants.serverUrl}/username/get?ownerId=$publicKey'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['username'] as String?;
    }
  } catch (_) {}
  return null;
}

  void _loadAll() {
    _items.clear();
    _loadContacts();
    _loadGroups();
    setState(() {});
  }

  void _loadContacts() {
    final contactsBox = Hive.box('contacts');
    for (final key in contactsBox.keys) {
      final data = contactsBox.get(key);
      if (data is Map) {
        final id = data['id']?.toString() ?? key;
        final name = data['name']?.toString() ?? 'Контакт';
        final initial = data['initial']?.toString() ?? '?';
        final exists = _items.any((c) => c['id'] == id && c['type'] == 'contact');
        if (!exists) {
          _items.add({
            'id': id,
            'name': name,
            'initial': initial,
            'status': data['status'] ?? 'В сети',
            'type': 'contact',
            'lastMessage': _getLastMessage(id),
            'lastTime': _getLastTime(id),
            'unreadCount': _chatService.getUnreadCount(id),
          });
        }
      }
    }
  }

  void _loadGroups() {
    final groupsBox = Hive.box('messages');
    final raw = groupsBox.get('groups_list');
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final id = item['id']?.toString() ?? '';
          final name = item['name']?.toString() ?? 'Группа';
          final exists = _items.any((c) => c['id'] == id && c['type'] == 'group');
          if (!exists) {
            _items.add({
              'id': id,
              'name': name,
              'initial': '👥',
              'status': 'Группа',
              'type': 'group',
              'memberCount': item['members']?.length ?? 0,
              'lastMessage': _getLastMessage(id),
              'lastTime': _getLastTime(id),
            });
          }
        }
      }
    }
  }

  String _getLastMessage(String chatId) {
    try {
      return _chatService.getLastMessage(chatId)?['text'] ?? 'Нет сообщений';
    } catch (_) {
      return 'Нет сообщений';
    }
  }

  String _getLastTime(String chatId) {
    try {
      return _chatService.getLastMessage(chatId)?['time'] ?? '';
    } catch (_) {
      return '';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'В сети':
        return const Color(0xFF10B981);
      case 'Был недавно':
        return Colors.orange;
      default:
        return const Color(0xFF71717A);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  Future<void> _deleteChat(String chatId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Удалить чат?'),
        content: Text(
          'Все сообщения в чате с "$name" будут удалены без возможности восстановления.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
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
      _chatService.deleteChat(chatId);
      setState(() {
        _items.removeWhere((c) => c['id'] == chatId);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Чат "$name" удалён'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _syncMessages() async {
    final p2p = P2PService();
    p2p.start();
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.syncing), duration: const Duration(seconds: 1)),
    );
    await Future.delayed(const Duration(seconds: 2));
    final messages = await p2p.syncAllMessages();
    await p2p.applySync(messages);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.syncDone(messages.length)),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _items.where((item) {
      final query = _searchQuery.toLowerCase();
      final name = (item['name'] ?? '').toLowerCase();
      return query.isEmpty || name.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final aTime = a['lastTime'] ?? '';
      final bTime = b['lastTime'] ?? '';
      return bTime.compareTo(aTime);
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: l10n.search,
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    VeilConstants.appName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
        actions: [
          // ============================================================
          // КНОПКА ПЕРЕКЛЮЧЕНИЯ НА DESKTOP РЕЖИМ
          // ============================================================
          IconButton(
            icon: const Icon(Icons.desktop_windows),
            onPressed: () => context.go('/desktop'),
            tooltip: 'Desktop режим',
          ),
          if (_isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.vpn_key),
              onPressed: () => context.go('/access'),
              tooltip: 'Доступ',
            ),
            IconButton(
              icon: const Icon(Icons.verified_user),
              onPressed: () => context.go('/doc-verify'),
              tooltip: 'Проверка документа',
            ),
          ],
          IconButton(
            icon: _isSearching ? const Icon(Icons.close) : const Icon(Icons.search),
            onPressed: _toggleSearch,
            tooltip: l10n.search,
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncMessages,
            tooltip: l10n.sync,
          ),
          IconButton(
            icon: const Icon(Icons.note_outlined),
            onPressed: () => context.go('/notes'),
            tooltip: l10n.notes,
          ),
          IconButton(
  icon: const Icon(Icons.search),
  onPressed: () => context.go('/search'),
  tooltip: 'Поиск',
),
          IconButton(
            icon: const Icon(Icons.campaign),
            onPressed: () => context.go('/channels'),
            tooltip: l10n.channels,
          ),
          IconButton(
            icon: const Icon(Icons.circle, color: Color(0xFF10B981), size: 12),
            onPressed: () => context.go('/stories'),
            tooltip: l10n.stories,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 40,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noChats,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final isGroup = item['type'] == 'group';
                final chatId = item['id']!;
                final lastMsg = item['lastMessage'] ?? 'Нет сообщений';
                final lastTime = item['lastTime'] ?? '';
                final status = item['status'] ?? '';
                final statusColor = _getStatusColor(status);
                final unreadCount = item['unreadCount'] ?? 0;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + index * 30),
                  curve: Curves.easeOut,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(20 * (1 - value), 0),
                      child: child,
                    ),
                  ),
                  child: Card(
                    color: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (isGroup) {
                          context.go('/group/$chatId');
                        } else {
                          context.go('/chat/$chatId');
                        }
                      },
                      onLongPress: () => _deleteChat(chatId, item['name'] ?? 'Контакт'),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: isGroup
                                    ? const LinearGradient(
                                        colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
                                      )
                                    : const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                                      ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: isGroup
                                    ? const Icon(Icons.group, color: Colors.white, size: 24)
                                    : Text(
                                        item['initial'] ?? '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['name'] ?? 'Неизвестный',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (lastTime.isNotEmpty)
                                        Text(
                                          lastTime,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      if (!isGroup && status.isNotEmpty) ...[
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: statusColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      if (isGroup) ...[
                                        Icon(Icons.group, size: 14, color: const Color(0xFF6C5CE7)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${item['memberCount'] ?? 0} участников',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Text(
                                          lastMsg,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ),
                                      if (unreadCount > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '$unreadCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!isGroup)
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C5CE7).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.call_outlined, size: 20),
                                  color: const Color(0xFF6C5CE7),
                                  onPressed: () => context.go(
                                    '/call/${item['id']}',
                                    extra: {'name': item['name'], 'isVideo': false},
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddDialog(context, l10n),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Добавить',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildAddOption(
                icon: Icons.qr_code_scanner,
                title: 'Сканировать QR',
                subtitle: 'Добавить контакт по QR-коду',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/scan');
                },
              ),
              _buildAddOption(
                icon: Icons.group_add,
                title: 'Создать группу',
                subtitle: 'Новый групповой чат',
                color: const Color(0xFF6C5CE7),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/create-group');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}