import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownParser {
  static List<TextSpan> parse(
    String text,
    TextStyle baseStyle, {
    VoidCallback? onUsernameTap,
    Function(String)? onVeilLinkTap,
  }) {
    print('📝 Парсим текст: "$text"');

    if (text.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final List<TextSpan> spans = [];
    int currentIndex = 0;

    // Поддерживаем: http, https, www, veil://, @username
    final urlRegex = RegExp(
      r'(https?://[^\s]+)|(www\.[^\s]+)|(veil://[^\s]+)|(@[a-zA-Z0-9_]+)',
      caseSensitive: false,
    );

    while (currentIndex < text.length) {
      // Жирный **текст**
      if (text.startsWith('**', currentIndex)) {
        final end = text.indexOf('**', currentIndex + 2);
        if (end != -1) {
          final content = text.substring(currentIndex + 2, end);
          spans.add(TextSpan(
            text: content,
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ));
          currentIndex = end + 2;
          continue;
        }
      }

      // Курсив *текст*
      if (text.startsWith('*', currentIndex)) {
        final end = text.indexOf('*', currentIndex + 1);
        if (end != -1) {
          final content = text.substring(currentIndex + 1, end);
          spans.add(TextSpan(
            text: content,
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ));
          currentIndex = end + 1;
          continue;
        }
      }

      // Код `текст`
      if (text.startsWith('`', currentIndex)) {
        final end = text.indexOf('`', currentIndex + 1);
        if (end != -1) {
          final content = text.substring(currentIndex + 1, end);
          spans.add(TextSpan(
            text: content,
            style: baseStyle.copyWith(
              fontFamily: 'SpaceMono',
              backgroundColor: Colors.grey.withOpacity(0.2),
            ),
          ));
          currentIndex = end + 1;
          continue;
        }
      }

      // Зачёркнутый ~~текст~~
      if (text.startsWith('~~', currentIndex)) {
        final end = text.indexOf('~~', currentIndex + 2);
        if (end != -1) {
          final content = text.substring(currentIndex + 2, end);
          spans.add(TextSpan(
            text: content,
            style: baseStyle.copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ));
          currentIndex = end + 2;
          continue;
        }
      }

      // Проверяем ссылки
      final match = urlRegex.matchAsPrefix(text, currentIndex);
      if (match != null) {
        final url = match.group(0)!;
        final isUsername = url.startsWith('@');
        final isVeilLink = url.startsWith('veil://');
        final isHttpLink = url.startsWith('http://') || url.startsWith('https://');
        final isWwwLink = url.startsWith('www.');

        String fullUrl = url;

        if (isWwwLink) {
          fullUrl = 'https://$url';
        } else if (isHttpLink) {
          fullUrl = url;
        }

        spans.add(TextSpan(
          text: url,
          style: baseStyle.copyWith(
            color: const Color(0xFF6C5CE7),
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFF6C5CE7),
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (isUsername) {
                _openUsername(url.substring(1), onUsernameTap);
              } else if (isVeilLink) {
                _openVeilLink(url, onVeilLinkTap);
              } else {
                _openUrl(fullUrl);
              }
            },
        ));
        currentIndex += url.length;
        continue;
      }

      // Обычный текст
      spans.add(TextSpan(
        text: text[currentIndex],
        style: baseStyle,
      ));
      currentIndex++;
    }

    print('📝 Результат: ${spans.length} сегментов');
    return spans;
  }

  static void _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('❌ Не удалось открыть ссылку: $url');
      }
    } catch (e) {
      print('❌ Ошибка открытия ссылки: $e');
    }
  }

  static void _openVeilLink(String url, Function(String)? onVeilLinkTap) {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme == 'veil') {
        final path = uri.pathSegments;
        if (path.isNotEmpty && path[0] == 'user') {
          final username = path.length > 1 ? path[1] : '';
          if (username.isNotEmpty) {
            if (onVeilLinkTap != null) {
              onVeilLinkTap(username);
            } else {
              _openUsername(username, null);
            }
          }
        }
      }
    } catch (e) {
      print('❌ Ошибка обработки veil:// ссылки: $e');
    }
  }

  static void _openUsername(String username, VoidCallback? onUsernameTap) {
    if (onUsernameTap != null) {
      onUsernameTap();
    } else {
      print('🔗 Открываем профиль @$username');
    }
  }
}