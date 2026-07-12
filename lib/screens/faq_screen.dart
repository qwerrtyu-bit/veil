import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  final List<Map<String, String>> _faq = [
    {
      'q': 'Что такое Veil?',
      'a': 'Veil — P2P-мессенджер с абсолютной приватностью. Ни номера, ни почты, ни серверов. Все сообщения зашифрованы, даже разработчик не может их прочитать.'
    },
    {
      'q': 'Чем Veil отличается от Telegram, MAX, WhatsApp?',
      'a': 'Veil не требует номер телефона или email. Не имеет серверов — все сообщения передаются через P2P-сеть. Использует onion-маршрутизацию и forward secrecy. Открытый исходный код под MIT. Никто, включая разработчика, не может прочитать ваши сообщения.'
    },
    {
      'q': 'Как создать личность?',
      'a': 'При первом запуске нажмите «Создать личность», придумайте пароль (минимум 8 символов). Вы получите seed-фразу из 24 слов — запишите её на бумагу. Это единственный способ восстановить доступ.'
    },
    {
      'q': 'Что такое seed-фраза?',
      'a': 'Seed-фраза — 24 слова, которые являются ключом к вашей личности. Если вы потеряете пароль или устройство, только seed-фраза поможет восстановить доступ. Храните её в надёжном месте.'
    },
    {
      'q': 'Как добавить контакт?',
      'a': 'Нажмите + в списке чатов, затем введите публичный ключ друга или отсканируйте QR-код. Для максимальной безопасности сверьте кодовые слова при личной встрече.'
    },
    {
      'q': 'Мои сообщения точно никто не читает?',
      'a': 'Да. Сообщения шифруются сквозным шифрованием (E2EE) с использованием ChaCha20. Ключи хранятся только на вашем устройстве. Даже разработчик не имеет доступа.'
    },
    {
      'q': 'Что делать если забыл пароль?',
      'a': 'Восстановите личность через seed-фразу. На экране входа нажмите «Сбросить личность», затем на онбординге выберите «Восстановить из seed-фразы». Введите 24 слова и придумайте новый пароль.'
    },
    {
      'q': 'Как работают самоуничтожающиеся сообщения?',
      'a': 'В чате нажмите на иконку таймера и выберите время: 5, 30, 60 секунд или 5 минут. Сообщение исчезнет через заданное время у обоих собеседников.'
    },
    {
      'q': 'Что такое кодовые слова?',
      'a': 'Кодовые слова — два слова, сгенерированные из вашего публичного ключа. Сверьте их с собеседником при личной встрече. Если слова совпадают — канал безопасен, перехвата нет.'
    },
    {
      'q': 'Как отправить файл, фото или видео?',
      'a': 'В чате используйте кнопки: 📎 для файлов, 📷 для фото, 🎬 для видео. Все файлы шифруются перед отправкой.'
    },
    {
      'q': 'Что такое плагины .veilP?',
      'a': 'Плагины — расширения от сторонних разработчиков. Каждый плагин проверяется встроенным антивирусом. Отправьте свой плагин на проверку через @VeilMessenger или veil.plugins@proton.me'
    },
    {
      'q': 'Как удалить личность?',
      'a': 'Настройки → Опасная зона → Сбросить личность. Все данные будут удалены без возможности восстановления.'
    },
    {
      'q': 'Кто разрабатывает Veil?',
      'a': 'Veil создан разработчиком void (0xTima). Исходный код открыт под лицензией MIT на GitHub.'
    },
  ];

  int _expandedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('FAQ'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats')),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faq.length,
        itemBuilder: (context, index) {
          final isExpanded = _expandedIndex == index;
          return Card(
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _faq[index]['q']!,
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      _faq[index]['a']!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.6,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}