import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../data/chat_service.dart';
import '../../data/identity_service.dart';
import 'chat_list_panel.dart';
import 'chat_panel.dart';
import 'info_panel.dart';

class MainDesktopScreen extends ConsumerStatefulWidget {
  const MainDesktopScreen({super.key});

  @override
  ConsumerState<MainDesktopScreen> createState() => _MainDesktopScreenState();
}

class _MainDesktopScreenState extends ConsumerState<MainDesktopScreen> {
  String? _selectedChatId;
  String? _selectedChatName;
  bool _showInfoPanel = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
          tooltip: 'Вернуться в мобильный режим',
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Veil Desktop',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
            tooltip: 'Настройки',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/chats'),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: Row(
        children: [
          // ============================================================
          // ЛЕВАЯ ПАНЕЛЬ: Список чатов (ширина ~320px)
          // ============================================================
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF5F5F5),
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: ChatListPanel(
              onChatSelected: (chatId, chatName) {
                setState(() {
                  _selectedChatId = chatId;
                  _selectedChatName = chatName;
                });
              },
              selectedChatId: _selectedChatId,
            ),
          ),

          // ============================================================
          // ЦЕНТРАЛЬНАЯ ПАНЕЛЬ: Чат
          // ============================================================
          Expanded(
            child: _selectedChatId != null
                ? ChatPanel(
                    chatId: _selectedChatId!,
                    chatName: _selectedChatName ?? 'Чат',
                    onToggleInfo: () {
                      setState(() {
                        _showInfoPanel = !_showInfoPanel;
                      });
                    },
                  )
                : Container(
                    color: theme.scaffoldBackgroundColor,
                    child: Center(
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
                            'Выберите чат',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // ============================================================
          // ПРАВАЯ ПАНЕЛЬ: Информация о чате
          // ============================================================
          if (_showInfoPanel && _selectedChatId != null)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF5F5F5),
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: InfoPanel(
                chatId: _selectedChatId!,
                chatName: _selectedChatName ?? 'Чат',
                onClose: () {
                  setState(() {
                    _showInfoPanel = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}