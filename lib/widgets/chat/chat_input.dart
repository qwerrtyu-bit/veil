import 'package:flutter/material.dart';
import '../../core/icons.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onEmojiToggle;
  final VoidCallback onStickerPicker;
  final VoidCallback onPhoto;
  final VoidCallback onVideo;
  final VoidCallback onFile;
  final VoidCallback onSelfDestruct;
  final VoidCallback onVoice;
  final VoidCallback onPlugins;
  final bool showEmoji;
  final int selfDestruct;
  final bool isLoading;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onEmojiToggle,
    required this.onStickerPicker,
    required this.onPhoto,
    required this.onVideo,
    required this.onFile,
    required this.onSelfDestruct,
    required this.onVoice,
    required this.onPlugins,
    required this.showEmoji,
    required this.selfDestruct,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.extension, color: Color(0xFF6C5CE7)),
              onPressed: onPlugins,
              tooltip: 'Плагины',
            ),
            IconButton(
              icon: Icon(
                selfDestruct > 0 ? Icons.timer_rounded : Icons.timer_outlined,
                color: selfDestruct > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              onPressed: onSelfDestruct,
              tooltip: 'Таймер самоуничтожения',
            ),
            IconButton(
              icon: const Icon(VeilIcons.photo),
              color: theme.colorScheme.primary,
              onPressed: onPhoto,
              tooltip: 'Фото',
            ),
            IconButton(
              icon: const Icon(VeilIcons.video),
              color: theme.colorScheme.primary,
              onPressed: onVideo,
              tooltip: 'Видео',
            ),
            IconButton(
              icon: const Icon(VeilIcons.attachment),
              color: theme.colorScheme.primary,
              onPressed: onFile,
              tooltip: 'Файл',
            ),
            IconButton(
              icon: const Icon(Icons.mic_rounded),
              color: theme.colorScheme.primary,
              onPressed: onVoice,
              tooltip: 'Голосовое сообщение',
            ),
            IconButton(
              icon: Icon(
                showEmoji ? Icons.keyboard_rounded : VeilIcons.emoji,
                color: theme.colorScheme.primary,
              ),
              onPressed: onEmojiToggle,
              tooltip: 'Эмодзи',
            ),
            IconButton(
              icon: const Icon(VeilIcons.sticker),
              color: theme.colorScheme.primary,
              onPressed: onStickerPicker,
              tooltip: 'Стикеры',
            ),
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: const InputDecoration(
                  hintText: 'Сообщение...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isLoading ? null : onSend,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            VeilIcons.send,
                            color: theme.colorScheme.onPrimary,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}