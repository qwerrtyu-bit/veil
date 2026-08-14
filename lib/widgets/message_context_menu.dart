import 'package:flutter/material.dart';

class MessageContextMenu extends StatelessWidget {
  final VoidCallback onReply;
  final VoidCallback onReactions;
  final VoidCallback onPin;
  final VoidCallback onEdit;
  final VoidCallback onForward;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onExport;
  final bool isPinned;
  final Offset position;

  const MessageContextMenu({
    super.key,
    required this.onReply,
    required this.onReactions,
    required this.onPin,
    required this.onEdit,
    required this.onForward,
    required this.onSelect,
    required this.onDelete,
    required this.onExport,
    required this.isPinned,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          final clampedOpacity = value.clamp(0.0, 1.0); // ✅ фикс
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: clampedOpacity,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                color: Theme.of(context).colorScheme.surface,
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.reply,
                        label: 'Ответить',
                        onTap: onReply,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.emoji_emotions_outlined,
                        label: 'Реакции',
                        onTap: onReactions,
                      ),
                      _buildMenuItem(
                        context,
                        icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        label: isPinned ? 'Открепить' : 'Закрепить',
                        onTap: onPin,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.download_outlined,
                        label: 'Экспорт чата',
                        onTap: onExport,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.edit_outlined,
                        label: 'Редактировать',
                        onTap: onEdit,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.forward_outlined,
                        label: 'Переслать',
                        onTap: onForward,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.check_box_outlined,
                        label: 'Выбрать',
                        onTap: onSelect,
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        context,
                        icon: Icons.delete_outline,
                        label: 'Удалить',
                        onTap: onDelete,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? Colors.red : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? Colors.red : theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}