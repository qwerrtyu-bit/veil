import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../data/chat_service.dart';

enum ExportFormat { txt, json }

class ExportService {
  final ChatService _chatService = ChatService();

  Future<void> exportChat(String chatId, ExportFormat format) async {
    final messages = _chatService.loadMessages(chatId);
    if (messages.isEmpty) {
      throw Exception('Нет сообщений для экспорта');
    }

    String content;
    String extension;
    
    if (format == ExportFormat.txt) {
      content = _buildTxtExport(messages);
      extension = 'txt';
    } else {
      content = _buildJsonExport(messages);
      extension = 'json';
    }

    // Сохраняем через file_picker
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить чат',
      fileName: 'chat_export_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsString(content);
    }
  }

  String _buildTxtExport(List<Map<String, dynamic>> messages) {
    final buffer = StringBuffer();
    buffer.writeln(' ЭКСПОРТ ЧАТА ');
    buffer.writeln('Дата: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Сообщений: ${messages.length}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (final msg in messages) {
      final isMe = msg['isMe'] as bool;
      final sender = isMe ? '[Я]' : '[Собеседник]';
      final time = msg['time'] ?? '--:--';
      final text = msg['text'] ?? '';
      buffer.writeln('$time $sender: $text');
    }

    buffer.writeln();
    buffer.writeln('=' * 50);
    buffer.writeln('Конец экспорта');
    return buffer.toString();
  }

  String _buildJsonExport(List<Map<String, dynamic>> messages) {
    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'totalMessages': messages.length,
      'messages': messages.map((msg) {
        return {
          'time': msg['time'] ?? '',
          'isMe': msg['isMe'] ?? false,
          'text': msg['text'] ?? '',
          'reactions': msg['reactions'] ?? {},
          'isPinned': msg['isPinned'] ?? false,
          'type': msg['type'] ?? 'text',
        };
      }).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }
}