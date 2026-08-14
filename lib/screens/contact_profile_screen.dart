import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';

class ContactProfileScreen extends ConsumerStatefulWidget {
  final String contactId;
  final String contactName;
  final String? publicKey;

  const ContactProfileScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    this.publicKey,
  });

  @override
  ConsumerState<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends ConsumerState<ContactProfileScreen> {
  bool _isInContacts = false;
  String _displayKey = '';
  String _safetyWords = '';

  @override
  void initState() {
    super.initState();
    _checkContacts();
    _generateSafetyWords();
  }

  void _checkContacts() {
    final contactsBox = Hive.box('contacts');
    _isInContacts = contactsBox.containsKey(widget.contactId);
    setState(() {});
  }

  void _generateSafetyWords() {
    final key = widget.publicKey ?? widget.contactId;
    final hash = key.hashCode.abs();
    const adjectives = [
      'Фиолетовый', 'Быстрый', 'Тихий', 'Скрытый', 'Яркий',
      'Тёмный', 'Лёгкий', 'Глубокий', 'Чистый', 'Свежий',
      'Стальной', 'Огненный', 'Ледяной', 'Вольный', 'Смелый',
    ];
    const nouns = [
      'туман', 'замок', 'кристалл', 'дракон', 'маяк',
      'призрак', 'парус', 'феникс', 'гром', 'шёпот',
      'волк', 'орёл', 'тигр', 'дельфин', 'компас',
    ];

    final adjIndex = hash % adjectives.length;
    final nounIndex = (hash ~/ adjectives.length) % nouns.length;

    setState(() {
      _displayKey = key.length > 40
          ? '${key.substring(0, 20)}…${key.substring(key.length - 20)}'
          : key;
      _safetyWords = '${adjectives[adjIndex]} ${nouns[nounIndex]}';
    });
  }

  void _addContact() {
    final contactsBox = Hive.box('contacts');
    contactsBox.put(widget.contactId, {
      'id': widget.contactId,
      'name': widget.contactName,
      'initial': widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : '?',
      'status': 'В сети',
    });

    setState(() => _isInContacts = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Контакт "${widget.contactName}" добавлен!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _copyKey() {
    Clipboard.setData(ClipboardData(text: widget.publicKey ?? widget.contactId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ключ скопирован'),
        backgroundColor: Color(0xFF6C5CE7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Профиль'),
        leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () => context.go('/chats'),
),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Аватар
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.contactName.isNotEmpty
                      ? widget.contactName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.contactName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isInContacts ? 'В контактах ✅' : 'Не в контактах',
                style: TextStyle(
                  color: _isInContacts ? const Color(0xFF10B981) : Colors.grey[500],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Кодовые слова
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Кодовые слова',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _safetyWords,
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 18,
                          color: const Color(0xFF6C5CE7),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Сверьте эти слова при личной встрече',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Публичный ключ
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.key, size: 20, color: Color(0xFF6C5CE7)),
                        const SizedBox(width: 8),
                        Text(
                          'Публичный ключ',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: _copyKey,
                          tooltip: 'Копировать',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF0B0D17)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _displayKey,
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Кнопка добавления в контакты
            if (!_isInContacts)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Добавить в контакты'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}