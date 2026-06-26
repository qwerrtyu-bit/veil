import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/identity_service.dart';

class SafetyWordsScreen extends ConsumerStatefulWidget {
  const SafetyWordsScreen({super.key});

  @override
  ConsumerState<SafetyWordsScreen> createState() => _SafetyWordsScreenState();
}

class _SafetyWordsScreenState extends ConsumerState<SafetyWordsScreen> {
  final _identityService = IdentityService();
  String _words = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateWords();
  }

  Future<void> _generateWords() async {
    final publicKey = await _identityService.getPublicKey();
    if (publicKey != null) {
      setState(() {
        _words = _generateSafetyWords(publicKey);
        _isLoading = false;
      });
    }
  }

  String _generateSafetyWords(String key) {
    // Генерируем два слова из хеша публичного ключа
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

    return '${adjectives[adjIndex]} ${nouns[nounIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Кодовые слова'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Иконка
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          size: 50,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Заголовок
                    Text(
                      'Ваши кодовые слова',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Эти слова уникальны для вашего публичного ключа. Сверьте их с собеседником при личной встрече. Если слова совпадают — канал безопасен.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 32),

                    // Слова
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6C5CE7).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _words,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontFamily: 'SpaceMono',
                              color: const Color(0xFF6C5CE7),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Как использовать
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Как проверить безопасность',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStep('1', 'Откройте этот экран на своём устройстве'),
                          _buildStep('2', 'Попросите собеседника открыть такой же экран'),
                          _buildStep('3', 'Сравните слова. Они должны полностью совпадать'),
                          _buildStep('4', 'Если слова разные — возможен перехват!'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number, style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}