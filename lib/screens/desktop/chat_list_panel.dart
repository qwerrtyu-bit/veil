import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/chat_service.dart';

class ChatListPanel extends StatefulWidget {
  final Function(String, String) onChatSelected;
  final String? selectedChatId;

  const ChatListPanel({
    super.key,
    required this.onChatSelected,
    this.selectedChatId,
  });

  @override
  State<ChatListPanel> createState() => _ChatListPanelState();
}

class _ChatListPanelState extends State<ChatListPanel> {
  final _chatService = ChatService();
  final List<Map<String, dynamic>> _items = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  void _loadChats() {
    _items.clear();
    try {
      final contactsBox = Hive.box('contacts');
      for (final key in contactsBox.keys) {
        final data = contactsBox.get(key);
        if (data is Map) {
          _items.add({
            'id': key.toString(),
            'name': data['name']?.toString() ?? 'Контакт',
            'initial': data['name']?.toString()[0].toUpperCase() ?? '?',
            'type': 'contact',
            'lastMessage': _chatService.getLastMessage(key.toString())?['text'] ?? '',
            'lastTime': _chatService.getLastMessage(key.toString())?['time'] ?? '',
            'unreadCount': _chatService.getUnreadCount(key.toString()),
          });
        }
      }
    } catch (_) {}
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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

    return Column(
      children: [
        // ============================================================
        // Поиск
        // ============================================================
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Поиск...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),

        // ============================================================
        // Список чатов
        // ============================================================
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'Нет чатов',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isSelected = widget.selectedChatId == item['id'];
                    final unreadCount = item['unreadCount'] ?? 0;

                    return InkWell(
                      onTap: () {
                        widget.onChatSelected(item['id'], item['name']);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            // Аватар
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF6C5CE7),
                              child: Text(
                                item['initial'] ?? '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Информация
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'Неизвестный',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    item['lastMessage'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Время и непрочитанные
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  item['lastTime'] ?? '',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                                    fontSize: 11,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C5CE7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}