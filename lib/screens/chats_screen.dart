import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/chat_service.dart';
import '../core/constants.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final _chatService = ChatService();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _chats = [
    {'id': '1', 'name': 'Аноним', 'initial': 'А'},
    {'id': '2', 'name': 'Крипто Энтузиаст', 'initial': 'К'},
    {'id': '3', 'name': 'void', 'initial': 'V'},
  ];

  List<Map<String, dynamic>> _groups = [];
  List<String> _pinnedChats = [];
  List<String> _pinnedGroups = [];
  List<String> _archivedChats = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _loadPinned();
    _loadArchived();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadGroups() {
    final groupsBox = Hive.box('messages');
    final raw = groupsBox.get('groups_list');
    if (raw is List) {
      _groups = raw.where((item) => item is Map).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
  }

  void _loadPinned() {
    final box = Hive.box('settings');
    _pinnedChats = List<String>.from(box.get('pinnedChats', defaultValue: <String>[]));
    _pinnedGroups = List<String>.from(box.get('pinnedGroups', defaultValue: <String>[]));
  }

  void _loadArchived() {
    final box = Hive.box('settings');
    _archivedChats = List<String>.from(box.get('archivedChats', defaultValue: <String>[]));
  }

  void _togglePinChat(String chatId) {
    setState(() => _pinnedChats.contains(chatId) ? _pinnedChats.remove(chatId) : _pinnedChats.add(chatId));
    Hive.box('settings').put('pinnedChats', _pinnedChats);
  }

  void _togglePinGroup(String groupId) {
    setState(() => _pinnedGroups.contains(groupId) ? _pinnedGroups.remove(groupId) : _pinnedGroups.add(groupId));
    Hive.box('settings').put('pinnedGroups', _pinnedGroups);
  }

  void _toggleArchiveChat(String chatId) {
    setState(() => _archivedChats.contains(chatId) ? _archivedChats.remove(chatId) : _archivedChats.add(chatId));
    Hive.box('settings').put('archivedChats', _archivedChats);
  }

  String _getLastMessage(String chatId) {
    final last = _chatService.getLastMessage(chatId);
    return last?['text'] ?? 'Нет сообщений';
  }

  String _getLastTime(String chatId) {
    final last = _chatService.getLastMessage(chatId);
    return last?['time'] ?? '';
  }

  Widget _buildChatAvatar(String chatId, String initial) {
    final settingsBox = Hive.box('settings');
    final avatarId = settingsBox.get('profileAvatar', defaultValue: 'void');
    final customImage = settingsBox.get('customAvatar');
    const avatars = {
      'void': '🔒', 'ghost': '👻', 'ninja': '🥷', 'hacker': '💻',
      'mask': '🎭', 'eye': '👁️', 'fire': '🔥', 'star': '⭐',
    };

    if (avatarId == 'custom' && customImage != null) {
      return Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(image: MemoryImage(base64Decode(customImage)), fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Text(avatars[avatarId] ?? initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22))),
    );
  }

  List<Map<String, dynamic>> _filteredGroups() {
    final all = _groups.where((g) => !_pinnedGroups.contains(g['id'])).toList();
    if (_searchQuery.isEmpty) return all;
    return all.where((g) => (g['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  List<Map<String, String>> _filteredChats() {
    var all = _chats.where((c) => !_pinnedChats.contains(c['id']!) && !_archivedChats.contains(c['id']!)).toList();
    if (_searchQuery.isEmpty) return all;
    return all.where((c) => (c['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pinnedGroupsList = _groups.where((g) => _pinnedGroups.contains(g['id'])).toList();
    final pinnedChatsList = _chats.where((c) => _pinnedChats.contains(c['id'])).toList();
    final archivedChatsList = _chats.where((c) => _archivedChats.contains(c['id'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(VeilConstants.appName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () => context.go('/scan'), tooltip: 'Добавить контакт'),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.go('/settings')),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Поиск...', prefixIcon: const Icon(Icons.search, size: 22),
              filled: true, fillColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            if (pinnedGroupsList.isNotEmpty) ...[
              _buildSectionHeader('Закреплённые группы'),
              ...pinnedGroupsList.map((g) => _buildGroupTile(g, true)),
            ],
            if (pinnedChatsList.isNotEmpty) ...[
              _buildSectionHeader('Закреплённые чаты'),
              ...pinnedChatsList.map((c) => _buildChatTile(c, true)),
            ],
            if (pinnedGroupsList.isNotEmpty || pinnedChatsList.isNotEmpty)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Divider(color: Colors.grey[300])),
            if (_filteredGroups().isNotEmpty) ...[
              _buildSectionHeader('Группы'),
              ..._filteredGroups().map((g) => _buildGroupTile(g, false)),
            ],
            if (_filteredChats().isNotEmpty) ...[
              _buildSectionHeader('Чаты'),
              ..._filteredChats().map((c) => _buildChatTile(c, false)),
            ],
            if (archivedChatsList.isNotEmpty) ...[
              _buildSectionHeader('Архив'),
              ...archivedChatsList.map((c) => _buildChatTile(c, false, isArchived: true)),
            ],
            if (_filteredChats().isEmpty && _filteredGroups().isEmpty && pinnedChatsList.isEmpty && pinnedGroupsList.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(children: [
                  Container(width: 100, height: 100, decoration: BoxDecoration(color: const Color(0xFF6C5CE7).withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.chat_bubble_outline, size: 50, color: const Color(0xFF6C5CE7).withOpacity(0.5))),
                  const SizedBox(height: 24),
                  Text('Нет чатов', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  Text('Нажмите + чтобы добавить контакт или создать группу', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]), textAlign: TextAlign.center),
                ]),
              )),
          ],
        )),
      ]),
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton(heroTag: 'group', onPressed: () => context.go('/create-group'), backgroundColor: const Color(0xFF8B7CF0), mini: true, child: const Icon(Icons.group_add, color: Colors.white)),
        const SizedBox(height: 12),
        FloatingActionButton(heroTag: 'contact', onPressed: () => context.go('/scan'), backgroundColor: const Color(0xFF6C5CE7), child: const Icon(Icons.person_add, color: Colors.white)),
      ]),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.fromLTRB(20, 12, 16, 4), child: Text(title.toUpperCase(), style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)));
  }

  Widget _buildGroupTile(Map<String, dynamic> group, bool isPinned) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 0, color: isPinned ? const Color(0xFF6C5CE7).withOpacity(0.05) : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: isPinned ? BorderSide(color: const Color(0xFF6C5CE7).withOpacity(0.3)) : BorderSide.none),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/group/${group['id']}'),
          onLongPress: () => _togglePinGroup(group['id']),
          onSecondaryTap: () => _togglePinGroup(group['id']),
          child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8B7CF0), Color(0xFF6C5CE7)]), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.group, color: Colors.white, size: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(group['name'] ?? 'Группа', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
                if (isPinned) const Icon(Icons.push_pin, size: 16, color: Color(0xFF6C5CE7)),
              ]),
              const SizedBox(height: 4),
              Text('Групповой чат', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
            ])),
            IconButton(icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18, color: isPinned ? const Color(0xFF6C5CE7) : Colors.grey[400]), onPressed: () => _togglePinGroup(group['id'])),
          ])),
        ),
      ),
    );
  }

  Widget _buildChatTile(Map<String, String> chat, bool isPinned, {bool isArchived = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lastMsg = _getLastMessage(chat['id']!);
    final lastTime = _getLastTime(chat['id']!);

    return Dismissible(
      key: Key('archive_${chat['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async { _toggleArchiveChat(chat['id']!); return false; },
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.orange.withOpacity(0.1), child: const Icon(Icons.archive, color: Colors.orange)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Card(
          elevation: 0, color: isArchived ? Colors.grey.withOpacity(0.05) : (isPinned ? const Color(0xFF6C5CE7).withOpacity(0.05) : (isDark ? const Color(0xFF1A1A2E) : Colors.white)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: isPinned ? BorderSide(color: const Color(0xFF6C5CE7).withOpacity(0.3)) : BorderSide.none),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.go('/chat/${chat['id']}'),
            onLongPress: () => _togglePinChat(chat['id']!),
            onSecondaryTap: () => _togglePinChat(chat['id']!),
            child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              _buildChatAvatar(chat['id']!, chat['initial'] ?? '?'),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(chat['name'] ?? 'Неизвестный', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
                  if (isPinned) const Icon(Icons.push_pin, size: 16, color: Color(0xFF6C5CE7)),
                  if (isArchived) const Icon(Icons.archive, size: 16, color: Colors.orange),
                ]),
                const SizedBox(height: 4),
                Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
              ])),
              const SizedBox(width: 8),
              Column(children: [
                Text(lastTime, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                const SizedBox(height: 4),
                IconButton(icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 16, color: isPinned ? const Color(0xFF6C5CE7) : Colors.grey[400]), onPressed: () => _togglePinChat(chat['id']!), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ]),
            ])),
          ),
        ),
      ),
    );
  }
}