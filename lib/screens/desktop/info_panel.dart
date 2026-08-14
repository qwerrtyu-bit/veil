import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class InfoPanel extends StatelessWidget {
  final String chatId;
  final String chatName;
  final VoidCallback onClose;

  const InfoPanel({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Получаем контакт из Hive
    String contactKey = '';
    String contactStatus = 'В сети';
    try {
      final contactsBox = Hive.box('contacts');
      final data = contactsBox.get(chatId);
      if (data is Map) {
        contactKey = data['id']?.toString() ?? '';
        contactStatus = data['status']?.toString() ?? 'В сети';
      }
    } catch (_) {}

    return Column(
      children: [
        // ============================================================
        // Заголовок
        // ============================================================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Информация',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
              ),
            ],
          ),
        ),

        // ============================================================
        // Профиль
        // ============================================================
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF6C5CE7),
                child: Text(
                  chatName.isNotEmpty ? chatName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                chatName,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      contactStatus,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ============================================================
        // Действия
        // ============================================================
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              _buildActionTile(
                icon: Icons.call,
                label: 'Звонок',
                color: const Color(0xFF6C5CE7),
                onTap: () {},
              ),
              _buildActionTile(
                icon: Icons.videocam,
                label: 'Видеозвонок',
                color: const Color(0xFF6C5CE7),
                onTap: () {},
              ),
              _buildActionTile(
                icon: Icons.photo_library,
                label: 'Общие медиа',
                color: const Color(0xFF6C5CE7),
                onTap: () {},
              ),
              _buildActionTile(
                icon: Icons.attach_file,
                label: 'Общие файлы',
                color: const Color(0xFF6C5CE7),
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildActionTile(
                icon: Icons.block,
                label: 'Заблокировать',
                color: Colors.red,
                onTap: () {},
              ),
              _buildActionTile(
                icon: Icons.report,
                label: 'Пожаловаться',
                color: Colors.red,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
      dense: true,
    );
  }
}