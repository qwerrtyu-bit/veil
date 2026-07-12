// ========== lib/screens/chats_screen.dart ==========
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/chat_service.dart';
import '../data/p2p_service.dart';
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
    {'id': '1', 'name': 'Аноним', 'initial': 'А', 'status': 'В сети'},
    {'id': '2', 'name': 'Крипто Энтузиаст', 'initial': 'К', 'status': 'Был недавно'},
    {'id': '3', 'name': 'void', 'initial': 'V', 'status': 'Разработчик'},
    {'id': 'f120b9055653991a9e97e54a53d31363c2081f8c09e90cbe38e11117f62cac27', 'name': 'ПК', 'initial': 'P', 'status': 'В сети'},
    {'id': 'd72600aa1aef91d8ae80ad6f8735f029dc1bca7cb74dd03ecea6ad55a13b09e0', 'name': 'iPhone', 'initial': 'i', 'status': 'В сети'},
  ];

  List<Map<String, dynamic>> _groups = [];
  List<String> _pinnedChats = [];
  List<String> _pinnedGroups = [];

  @override
  void initState() {
    super.initState();
    _groups = [];
    _pinnedChats = [];
    _pinnedGroups = [];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getLastMessage(String chatId) {
    try { return _chatService.getLastMessage(chatId)?['text'] ?? 'Нет сообщений'; } catch (_) { return 'Нет сообщений'; }
  }

  String _getLastTime(String chatId) {
    try { return _chatService.getLastMessage(chatId)?['time'] ?? ''; } catch (_) { return ''; }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'В сети': return const Color(0xFF10B981);
      case 'Был недавно': return Colors.orange;
      default: return const Color(0xFF71717A);
    }
  }

  void _syncMessages() async {
    final p2p = P2PService();
    p2p.start();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Синхронизация...'), duration: Duration(seconds: 1)));
    await Future.delayed(const Duration(seconds: 2));
    final messages = await p2p.syncAllMessages();
    await p2p.applySync(messages);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Синхронизировано: ${messages.length} сообщений'), backgroundColor: const Color(0xFF10B981)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _chats.where((c) => c['name']!.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(VeilConstants.appName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.sync), onPressed: _syncMessages, tooltip: 'Синхронизация'),
          IconButton(icon: const Icon(Icons.note_outlined), onPressed: () => context.go('/notes'), tooltip: 'Заметки'),
          IconButton(icon: const Icon(Icons.extension_outlined), onPressed: () => context.go('/plugins'), tooltip: 'Плагины'),
          IconButton(icon: const Icon(Icons.campaign), onPressed: () => context.go('/channels'), tooltip: 'Каналы'),
          IconButton(icon: const Icon(Icons.vpn_key), onPressed: () => context.go('/access'), tooltip: 'Доступ'),
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () => context.go('/faq'), tooltip: 'FAQ'),
          IconButton(icon: const Icon(Icons.circle, color: Color(0xFF10B981), size: 12), onPressed: () => context.go('/stories'), tooltip: 'Статусы'),
          IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () => context.go('/scan'), tooltip: 'Добавить'),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.go('/settings')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(hintText: 'Поиск...', prefixIcon: const Icon(Icons.search, size: 20), filled: true,
                  fillColor: isDark ? const Color(0xFF18181B) : const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[700]),
                    const SizedBox(height: 16), Text('Нет чатов', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final chat = filtered[index];
                      final lastMsg = _getLastMessage(chat['id']!);
                      final lastTime = _getLastTime(chat['id']!);
                      final status = chat['status'] ?? '';
                      final statusColor = _getStatusColor(status);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Card(
                          color: isDark ? const Color(0xFF18181B) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.go('/chat/${chat['id']}'),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(children: [
                                Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]), borderRadius: BorderRadius.circular(14)),
                                  child: Center(child: Text(chat['initial'] ?? '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(child: Text(chat['name'] ?? 'Неизвестный', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
                                      Text(lastTime, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                    ]),
                                    const SizedBox(height: 3),
                                    Row(children: [
                                      if (status.isNotEmpty) ...[
                                        Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                                        const SizedBox(width: 4),
                                        Text(status, style: TextStyle(fontSize: 11, color: statusColor)),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(child: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
                                    ]),
                                  ]),
                                ),
                                IconButton(icon: const Icon(Icons.call_outlined, size: 20), color: const Color(0xFF10B981),
                                    onPressed: () => context.go('/call/${chat['id']}', extra: {'name': chat['name'], 'isVideo': false})),
                              ]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => context.go('/scan'), backgroundColor: const Color(0xFF10B981), child: const Icon(Icons.add, color: Colors.white)),
    );
  }
}