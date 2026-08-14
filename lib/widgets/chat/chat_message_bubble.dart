import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../encrypt_animation.dart';
import '../markdown_parser.dart';
import 'dart:convert';

class ChatMessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool isAnimating;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;
  final String? currentUserId;
  final String? senderUsername;
  final VoidCallback? onUsernameTap;
  final Function(String)? onVeilLinkTap;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isAnimating = false,
    this.onLongPress,
    this.onReply,
    this.currentUserId,
    this.senderUsername,
    this.onUsernameTap,
    this.onVeilLinkTap,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPinned = widget.message['isPinned'] as bool? ?? false;
    final isEdited = widget.message['isEdited'] as bool? ?? false;
    final senderUsername = widget.senderUsername ?? widget.message['senderUsername'] as String?;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Align(
          alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: widget.onLongPress,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: widget.isMe
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF6C5CE7),
                          const Color(0xFF8B7CF0),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          const Color(0xFF1A1A2E).withOpacity(0.8),
                          const Color(0xFF1A1A2E).withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                  bottomRight: Radius.circular(widget.isMe ? 4 : 16),
                ),
                boxShadow: widget.isMe
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isMe && senderUsername != null && senderUsername.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '@$senderUsername',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF6C5CE7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isPinned)
                    Row(
                      children: [
                        Icon(Icons.push_pin, size: 14, color: const Color(0xFF6C5CE7)),
                        const SizedBox(width: 4),
                        Text(
                          'Закреплено',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF6C5CE7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  if (widget.message['replyTo'] != null)
                    _buildReplyPreview(context, theme),
                  if (widget.message['type'] == 'photo' ||
                      widget.message['type'] == 'file' ||
                      widget.message['type'] == 'video')
                    _buildFilePreview(context, theme),
                  if (widget.isAnimating)
                    EncryptAnimation(
                      text: widget.message['text'] as String,
                      isEncrypting: true,
                      textColor: widget.isMe ? Colors.white : const Color(0xFFF4F4F5),
                      fontSize: 16,
                    )
                  else
                    _buildMessageText(context),
                  if (isEdited)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Отредактировано',
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.isMe
                              ? Colors.white.withOpacity(0.5)
                              : const Color(0xFF71717A).withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.message['time'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isMe
                              ? Colors.white.withOpacity(0.7)
                              : const Color(0xFF71717A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildReadIndicator(),
                    ],
                  ),
                  _buildReactions(context, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, ThemeData theme) {
    final replyTo = widget.message['replyTo'] as Map<String, dynamic>?;
    if (replyTo == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.isMe
            ? Colors.white.withOpacity(0.15)
            : const Color(0xFF0A0A0F).withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: widget.isMe ? Colors.white : const Color(0xFF6C5CE7),
            width: 3,
          ),
        ),
      ),
      child: Text(
        replyTo['text'] ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: widget.isMe
              ? Colors.white.withOpacity(0.7)
              : const Color(0xFFA1A1AA),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context, ThemeData theme) {
    final type = widget.message['type'] as String;
    final isPhoto = type == 'photo';
    final isVideo = type == 'video';
    final isFile = type == 'file';

    if (isPhoto) {
      final imageData = widget.message['imageData'] as String?;
      if (imageData != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(imageData),
            height: 150,
            width: 200,
            fit: BoxFit.cover,
          ),
        );
      }
      return const Icon(Icons.image, size: 40);
    }

    if (isVideo) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.video_library, color: Color(0xFF6C5CE7), size: 30),
          const SizedBox(width: 8),
          Text(
            '🎬 Видео',
            style: TextStyle(
              color: widget.isMe ? Colors.white : const Color(0xFFF4F4F5),
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file, color: widget.isMe ? Colors.white : const Color(0xFF6C5CE7)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.message['fileName'] ?? 'Файл',
            style: TextStyle(
              color: widget.isMe ? Colors.white : const Color(0xFFF4F4F5),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageText(BuildContext context) {
    final text = widget.message['text'] as String? ?? '';
    print('📝 Текст сообщения: "$text"');

    final baseStyle = TextStyle(
      color: widget.isMe ? Colors.white : const Color(0xFFE8E8E8),
      fontSize: 16,
    );

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return RichText(
      text: TextSpan(
        children: MarkdownParser.parse(
          text,
          baseStyle,
          onUsernameTap: widget.onUsernameTap,
          onVeilLinkTap: widget.onVeilLinkTap,
        ),
      ),
    );
  }

  Widget _buildReadIndicator() {
    if (widget.message['isMe'] != true) return const SizedBox.shrink();
    final isRead = widget.message['isRead'] ?? true;
    return Icon(
      isRead ? Icons.check_circle : Icons.circle_outlined,
      size: 12,
      color: isRead
          ? Colors.white.withOpacity(0.7)
          : Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildReactions(BuildContext context, ThemeData theme) {
    final reactions = widget.message['reactions'] as Map? ?? {};
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: reactions.entries.map((entry) {
          final emoji = entry.key.toString();
          final count = (entry.value as List).length;
          final hasMyReaction = (entry.value as List).contains(widget.currentUserId);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: hasMyReaction
                  ? const Color(0xFF6C5CE7).withOpacity(0.2)
                  : const Color(0xFF1A1A2E).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasMyReaction
                    ? const Color(0xFF6C5CE7)
                    : const Color(0xFF1A1A2E).withOpacity(0.3),
              ),
            ),
            child: Text(
              '$emoji $count',
              style: TextStyle(
                fontSize: 12,
                color: hasMyReaction
                    ? const Color(0xFF6C5CE7)
                    : const Color(0xFFA1A1AA),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}