import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'plugin_api.dart';

class VeilTranslator {
  static const String id = 'veil.translator';
  static const String name = 'Veil Translator';
  static const String version = '1.0.0';
  static const String author = 'Veil Team';

  static void register(PluginAPI api) {
    print('Veil Translator зарегистрирован');

    api.registerCommand('translate', (params) {
      final text = params['text'] as String?;
      final targetLang = params['targetLang'] ?? 'ru';
      if (text == null || text.isEmpty) {
        return {'error': 'Нет текста для перевода'};
      }
      
      // Простая имитация перевода для демонстрации
      final mockTranslations = {
        'hello': {'ru': 'привет', 'en': 'hello', 'fr': 'bonjour', 'de': 'hallo'},
        'how are you': {'ru': 'как дела', 'en': 'how are you', 'fr': 'comment ça va', 'de': 'wie geht es dir'},
        'goodbye': {'ru': 'до свидания', 'en': 'goodbye', 'fr': 'au revoir', 'de': 'auf wiedersehen'},
        'thank you': {'ru': 'спасибо', 'en': 'thank you', 'fr': 'merci', 'de': 'danke'},
        'yes': {'ru': 'да', 'en': 'yes', 'fr': 'oui', 'de': 'ja'},
        'no': {'ru': 'нет', 'en': 'no', 'fr': 'non', 'de': 'nein'},
      };

      final lowerText = text.toLowerCase();
      String translated = text;
      
      for (final entry in mockTranslations.entries) {
        if (lowerText.contains(entry.key)) {
          translated = entry.value[targetLang] ?? text;
          break;
        }
      }
      
      return {
        'original': text,
        'translated': translated,
        'targetLang': targetLang,
      };
    });

    api.registerCommand('get_languages', (params) {
      return {
        'languages': [
          {'code': 'ru', 'name': 'Русский'},
          {'code': 'en', 'name': 'English'},
          {'code': 'fr', 'name': 'Français'},
          {'code': 'de', 'name': 'Deutsch'},
          {'code': 'es', 'name': 'Español'},
          {'code': 'it', 'name': 'Italiano'},
        ]
      };
    });
  }
}

class VeilReminder {
  static const String id = 'veil.reminder';
  static const String name = 'Veil Reminder';
  static const String version = '1.0.0';
  static const String author = 'Veil Team';

  static Timer? _timer;

  static void register(PluginAPI api) {
    print('Veil Reminder зарегистрирован');

    api.registerCommand('reminder.set', (params) {
      final chatId = params['chatId'] as String?;
      final text = params['text'] as String?;
      final delay = params['delay'] as int? ?? 10;
      
      if (chatId == null || text == null) {
        return {'error': 'Не указан чат или текст'};
      }
      
      final reminder = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'chatId': chatId,
        'text': text,
        'createdAt': DateTime.now().toIso8601String(),
        'triggerAt': DateTime.now().add(Duration(seconds: delay)).toIso8601String(),
        'done': false,
      };
      
      final box = Hive.box('settings');
      final reminders = box.get('reminders', defaultValue: <Map>[]);
      reminders.add(reminder);
      box.put('reminders', reminders);
      
      return {
        'status': 'success',
        'message': 'Напоминание установлено на $delay секунд',
        'reminder': reminder,
      };
    });

    api.registerCommand('reminder.get', (params) {
      final box = Hive.box('settings');
      final reminders = box.get('reminders', defaultValue: <Map>[]);
      return {
        'reminders': reminders.where((r) => r['done'] != true).toList(),
        'total': reminders.length,
      };
    });

    api.registerCommand('reminder.remove', (params) {
      final id = params['id'] as String?;
      if (id == null) return {'error': 'Не указан ID'};
      final box = Hive.box('settings');
      final reminders = box.get('reminders', defaultValue: <Map>[]);
      reminders.removeWhere((r) => r['id'] == id);
      box.put('reminders', reminders);
      return {'status': 'success', 'message': 'Напоминание удалено'};
    });

    api.registerLifecycle('onLoad', () {
      _startChecker(api);
    });

    api.registerLifecycle('onUnload', () {
      _timer?.cancel();
    });
  }

  static void _startChecker(PluginAPI api) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      try {
        final box = Hive.box('settings');
        final reminders = box.get('reminders', defaultValue: <Map>[]);
        final now = DateTime.now();
        bool changed = false;
        
        for (final r in reminders) {
          if (r['done'] == true) continue;
          final triggerAt = DateTime.parse(r['triggerAt']);
          if (now.isAfter(triggerAt)) {
            final chatId = r['chatId'] as String;
            final text = r['text'] as String;
            
            api.emit('notification', {
              'title': 'Напоминание',
              'body': text,
              'chatId': chatId,
            });
            
            r['done'] = true;
            changed = true;
            
            print('Напоминание сработало: $text');
          }
        }
        
        if (changed) {
          box.put('reminders', reminders);
        }
      } catch (e) {
        print('Ошибка в проверке напоминаний: $e');
      }
    });
  }
}

class VeilStats {
  static const String id = 'veil.stats';
  static const String name = 'Veil Stats';
  static const String version = '1.0.0';
  static const String author = 'Veil Team';

  static void register(PluginAPI api) {
    print('Veil Stats зарегистрирован');

    api.registerCommand('stats.chat', (params) {
      final chatId = params['chatId'] as String?;
      if (chatId == null) return {'error': 'Не указан чат'};
      
      try {
        final box = Hive.box('messages');
        final messages = box.get(chatId, defaultValue: <Map>[]);
        
        if (messages.isEmpty) {
          return {'total': 0, 'message': 'Нет сообщений'};
        }
        
        int myMessages = 0;
        int theirMessages = 0;
        int totalLength = 0;
        
        for (final msg in messages) {
          if (msg is Map) {
            if (msg['isMe'] == true) {
              myMessages++;
            } else {
              theirMessages++;
            }
            final text = msg['text'] as String? ?? '';
            totalLength += text.length;
          }
        }
        
        return {
          'total': messages.length,
          'myMessages': myMessages,
          'theirMessages': theirMessages,
          'avgLength': messages.isNotEmpty ? (totalLength / messages.length).round() : 0,
        };
      } catch (e) {
        return {'error': 'Ошибка получения статистики: $e'};
      }
    });

    api.registerCommand('stats.words', (params) {
      final chatId = params['chatId'] as String?;
      if (chatId == null) return {'error': 'Не указан чат'};
      
      try {
        final box = Hive.box('messages');
        final messages = box.get(chatId, defaultValue: <Map>[]);
        final words = <String, int>{};
        
        for (final msg in messages) {
          if (msg is Map) {
            final text = msg['text'] as String? ?? '';
            for (final word in text.split(' ')) {
              final clean = word.replaceAll(RegExp(r'[^a-zA-Zа-яА-Я]'), '');
              if (clean.length > 2) {
                final lower = clean.toLowerCase();
                words[lower] = (words[lower] ?? 0) + 1;
              }
            }
          }
        }
        
        final sorted = words.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        return {
          'topWords': sorted.take(10).map((e) => {'word': e.key, 'count': e.value}).toList(),
          'totalWords': words.values.fold(0, (a, b) => a + b),
        };
      } catch (e) {
        return {'error': 'Ошибка получения статистики: $e'};
      }
    });
  }
}

class VeilScheduler {
  static const String id = 'veil.scheduler';
  static const String name = 'Veil Scheduler';
  static const String version = '1.0.0';
  static const String author = 'Veil Team';

  static Timer? _timer;

  static void register(PluginAPI api) {
    print('Veil Scheduler зарегистрирован');

    api.registerCommand('scheduler.schedule', (params) {
      final chatId = params['chatId'] as String?;
      final text = params['text'] as String?;
      final delay = params['delay'] as int? ?? 30;
      
      if (chatId == null || text == null) {
        return {'error': 'Не указан чат или текст'};
      }
      
      final scheduled = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'chatId': chatId,
        'text': text,
        'createdAt': DateTime.now().toIso8601String(),
        'sendAt': DateTime.now().add(Duration(seconds: delay)).toIso8601String(),
        'sent': false,
      };
      
      final box = Hive.box('settings');
      final list = box.get('scheduled', defaultValue: <Map>[]);
      list.add(scheduled);
      box.put('scheduled', list);
      
      return {
        'status': 'success',
        'message': 'Сообщение запланировано на $delay секунд',
        'scheduled': scheduled,
      };
    });

    api.registerCommand('scheduler.get', (params) {
      final box = Hive.box('settings');
      final list = box.get('scheduled', defaultValue: <Map>[]);
      return {
        'scheduled': list.where((s) => s['sent'] != true).toList(),
        'total': list.length,
      };
    });

    api.registerCommand('scheduler.cancel', (params) {
      final id = params['id'] as String?;
      if (id == null) return {'error': 'Не указан ID'};
      final box = Hive.box('settings');
      final list = box.get('scheduled', defaultValue: <Map>[]);
      list.removeWhere((s) => s['id'] == id);
      box.put('scheduled', list);
      return {'status': 'success', 'message': 'Сообщение отменено'};
    });

    api.registerLifecycle('onLoad', () {
      _startScheduler(api);
    });
  }

  static void _startScheduler(PluginAPI api) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final box = Hive.box('settings');
        final list = box.get('scheduled', defaultValue: <Map>[]);
        final now = DateTime.now();
        bool changed = false;
        
        for (final s in list) {
          if (s['sent'] == true) continue;
          final sendAt = DateTime.parse(s['sendAt']);
          if (now.isAfter(sendAt)) {
            final chatId = s['chatId'] as String;
            final text = s['text'] as String;
            
            await api.sendMessage(chatId, text);
            s['sent'] = true;
            changed = true;
            
            api.emit('notification', {
              'title': 'Сообщение отправлено',
              'body': text,
              'chatId': chatId,
            });
            
            print('Отложенное сообщение отправлено: $text');
          }
        }
        
        if (changed) {
          box.put('scheduled', list);
        }
      } catch (e) {
        print('Ошибка в планировщике: $e');
      }
    });
  }
}

class VeilSafeBackup {
  static const String id = 'veil.safe_backup';
  static const String name = 'Veil Safe Backup';
  static const String version = '1.0.0';
  static const String author = 'Veil Team';

  static Timer? _timer;

  static void register(PluginAPI api) {
    print('Veil Safe Backup зарегистрирован');

    api.registerCommand('backup.now', (params) {
      final chatId = params['chatId'] as String?;
      if (chatId == null) return {'error': 'Не указан чат'};
      
      try {
        final box = Hive.box('messages');
        final messages = box.get(chatId, defaultValue: <Map>[]);
        final backupBox = Hive.box('backups');
        final backupId = 'backup_${DateTime.now().millisecondsSinceEpoch}';
        
        backupBox.put(backupId, {
          'chatId': chatId,
          'messages': messages,
          'createdAt': DateTime.now().toIso8601String(),
          'size': messages.length,
        });
        
        return {
          'status': 'success',
          'backupId': backupId,
          'messages': messages.length,
          'createdAt': DateTime.now().toIso8601String(),
        };
      } catch (e) {
        return {'error': 'Ошибка создания бэкапа: $e'};
      }
    });

    api.registerCommand('backup.restore', (params) {
      final backupId = params['backupId'] as String?;
      if (backupId == null) return {'error': 'Не указан ID'};
      
      try {
        final backupBox = Hive.box('backups');
        final backup = backupBox.get(backupId);
        if (backup == null) return {'error': 'Бэкап не найден'};
        
        final box = Hive.box('messages');
        box.put(backup['chatId'], backup['messages']);
        
        return {
          'status': 'success',
          'message': 'Чат восстановлен',
          'messages': backup['messages'].length,
        };
      } catch (e) {
        return {'error': 'Ошибка восстановления: $e'};
      }
    });

    api.registerCommand('backup.list', (params) {
      try {
        final backupBox = Hive.box('backups');
        final keys = backupBox.keys.toList();
        final result = <Map>[];
        
        for (final key in keys) {
          final data = backupBox.get(key);
          if (data is Map) {
            result.add({
              'id': key,
              'chatId': data['chatId'],
              'size': data['size'],
              'createdAt': data['createdAt'],
            });
          }
        }
        
        return {'backups': result, 'total': result.length};
      } catch (e) {
        return {'error': 'Ошибка получения списка бэкапов: $e'};
      }
    });

    api.registerLifecycle('onLoad', () {
      _startAutoBackup(api);
    });
  }

  static void _startAutoBackup(PluginAPI api) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      try {
        final box = Hive.box('settings');
        final lastBackup = box.get('last_backup_time');
        
        if (lastBackup != null) {
          final diff = DateTime.now().difference(DateTime.parse(lastBackup));
          if (diff.inHours < 24) return;
        }
        
        final messagesBox = Hive.box('messages');
        final backupBox = Hive.box('backups');
        
        for (final key in messagesBox.keys) {
          final messages = messagesBox.get(key);
          if (messages is List && messages.isNotEmpty) {
            backupBox.put('auto_${DateTime.now().millisecondsSinceEpoch}_$key', {
              'chatId': key,
              'messages': messages,
              'createdAt': DateTime.now().toIso8601String(),
              'size': messages.length,
            });
          }
        }
        
        box.put('last_backup_time', DateTime.now().toIso8601String());
        print('Автоматический бэкап выполнен');
      } catch (e) {
        print('Ошибка авто-бэкапа: $e');
      }
    });
  }
}

class VeilPluginRegistry {
  static void registerAll(PluginAPI api) {
    VeilTranslator.register(api);
    VeilReminder.register(api);
    VeilStats.register(api);
    VeilScheduler.register(api);
    VeilSafeBackup.register(api);
    print('Все плагины зарегистрированы!');
  }
}