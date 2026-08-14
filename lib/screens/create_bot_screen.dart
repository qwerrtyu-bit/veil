import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../services/bot_service.dart';
import '../data/identity_service.dart';
import '../models/bot_model.dart';

class CreateBotScreen extends ConsumerStatefulWidget {
  const CreateBotScreen({super.key});

  @override
  ConsumerState<CreateBotScreen> createState() => _CreateBotScreenState();
}

class _CreateBotScreenState extends ConsumerState<CreateBotScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _welcomeController = TextEditingController();
  final _botService = BotService();
  final _identityService = IdentityService();
  
  bool _isLoading = false;
  String? _errorText;
  VeilBot? _createdBot;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _createBot() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final welcome = _welcomeController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorText = 'Введите название бота');
      return;
    }

    if (username.isEmpty) {
      setState(() => _errorText = 'Введите юзернейм бота');
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() => _errorText = 'Юзернейм может содержать только буквы, цифры и _');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final publicKey = await _identityService.getPublicKey();
      if (publicKey == null) {
        setState(() {
          _errorText = 'Личность не найдена';
          _isLoading = false;
        });
        return;
      }

      final bot = await _botService.createBot(
        name: name,
        username: username,
        ownerPublicKey: publicKey,
        welcomeMessage: welcome.isNotEmpty ? welcome : null,
      );

      setState(() {
        _createdBot = bot;
        _isLoading = false;
      });

      // Копируем токен в буфер
      await Clipboard.setData(ClipboardData(text: bot.token));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Бот создан! Токен скопирован в буфер.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorText = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  void _copyToken() {
    if (_createdBot != null) {
      Clipboard.setData(ClipboardData(text: _createdBot!.token));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Токен скопирован'),
          backgroundColor: Color(0xFF6C5CE7),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Создать бота'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/bots'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _createdBot != null
            ? _buildSuccessScreen(theme)
            : _buildForm(theme),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6C5CE7).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF6C5CE7)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Бот будет иметь свой токен для доступа к API Veil. '
                  'Храните токен в секрете.',
                  style: TextStyle(
                    color: const Color(0xFF6C5CE7),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Название бота',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Мой бот',
            prefixIcon: Icon(Icons.smart_toy),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Юзернейм бота',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            hintText: 'my_bot',
            prefixIcon: Icon(Icons.alternate_email),
            helperText: 'Только буквы, цифры и _',
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Приветственное сообщение (необязательно)',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _welcomeController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Привет! Я бот Veil. Чем могу помочь?',
            prefixIcon: Icon(Icons.message_outlined),
          ),
        ),

        if (_errorText != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorText!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createBot,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Создать бота'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Color(0xFF10B981),
            size: 44,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Бот создан! 🎉',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _createdBot!.name,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${_createdBot!.username}',
          style: TextStyle(
            color: const Color(0xFF6C5CE7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6C5CE7)),
          ),
          child: Column(
            children: [
              const Text(
                'Токен бота',
                style: TextStyle(
                  color: Color(0xFF888899),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                _createdBot!.token,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 14,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyToken,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Копировать токен'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/bots'),
                child: const Text('К списку ботов'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.go('/chats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                ),
                child: const Text('В чаты'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}