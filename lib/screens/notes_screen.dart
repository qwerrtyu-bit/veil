import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/crypto_service.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _cryptoService = CryptoService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    final box = Hive.box('messages');
    final raw = box.get('notes', defaultValue: <Map<String, dynamic>>[]);
    if (raw is List) {
      _notes = raw.where((item) => item is Map).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    setState(() {});
  }

  Future<void> _addNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;

    final key = _cryptoService.createKeyFromString('veil_note_$title');
    final encrypted = await _cryptoService.encrypt(content, key);

    _notes.add({
      'title': title,
      'content': encrypted,
      'date': DateTime.now().toIso8601String().substring(0, 10),
    });

    Hive.box('messages').put('notes', _notes);
    _titleController.clear();
    _contentController.clear();
    setState(() {});
    Navigator.pop(context);
  }

  Future<void> _viewNote(int index) async {
    final note = _notes[index];
    final key = _cryptoService.createKeyFromString('veil_note_${note['title']}');
    String decrypted;
    try {
      decrypted = await _cryptoService.decrypt(note['content'] as String, key);
    } catch (_) {
      decrypted = 'Ошибка расшифровки';
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A26),
        title: Text(note['title'] as String, style: const TextStyle(color: Color(0xFFE0E0E0))),
        content: Text(decrypted, style: const TextStyle(color: Color(0xFFE0E0E0))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _deleteNote(int index) {
    setState(() => _notes.removeAt(index));
    Hive.box('messages').put('notes', _notes);
  }

  void _showAddDialog() {
    _titleController.clear();
    _contentController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A26),
        title: const Text('Новая .veilnote', style: TextStyle(color: Color(0xFFE0E0E0))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Color(0xFFE0E0E0)),
              decoration: const InputDecoration(
                hintText: 'Заголовок',
                hintStyle: TextStyle(color: Color(0xFF888899)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              style: const TextStyle(color: Color(0xFFE0E0E0)),
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Содержание',
                hintStyle: TextStyle(color: Color(0xFF888899)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(onPressed: _addNote, child: const Text('Сохранить', style: TextStyle(color: Color(0xFF4ADE80)))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Заметки (.veilnote)'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4ADE80),
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Color(0xFF0A0A0F)),
      ),
      body: _notes.isEmpty
          ? const Center(
              child: Text('Нет заметок', style: TextStyle(color: Color(0xFF888899), fontSize: 16)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  color: const Color(0xFF1A1A26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(note['title'] as String, style: const TextStyle(color: Color(0xFFE0E0E0))),
                    subtitle: Text(note['date'] as String, style: const TextStyle(color: Color(0xFF888899))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Color(0xFF4ADE80)),
                          onPressed: () => _viewNote(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                          onPressed: () => _deleteNote(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}