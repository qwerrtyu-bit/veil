import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/bot_model.dart';

class BotService {
  final Box _botsBox = Hive.box('bots');

  // Генерация токена для бота
  String _generateToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return 'veil_bot_' + List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // Создание нового бота
  Future<VeilBot> createBot({
    required String name,
    required String username,
    required String ownerPublicKey,
    String? welcomeMessage,
  }) async {
    final bot = VeilBot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      username: username,
      token: _generateToken(),
      ownerPublicKey: ownerPublicKey,
      welcomeMessage: welcomeMessage ?? 'Привет! Я бот Veil.',
      createdAt: DateTime.now(),
    );

    final bots = _getAllBots();
    bots.add(bot);
    await _saveBots(bots);

    return bot;
  }

  // Получение всех ботов пользователя
  List<VeilBot> getBotsByOwner(String publicKey) {
    return _getAllBots().where((b) => b.ownerPublicKey == publicKey).toList();
  }

  // Получение бота по токену
  VeilBot? getBotByToken(String token) {
    try {
      return _getAllBots().firstWhere((b) => b.token == token);
    } catch (_) {
      return null;
    }
  }

  // Получение бота по ID
  VeilBot? getBotById(String id) {
    try {
      return _getAllBots().firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  // Активация/деактивация бота
  Future<void> toggleBot(String id) async {
    final bots = _getAllBots();
    final index = bots.indexWhere((b) => b.id == id);
    if (index != -1) {
      bots[index] = VeilBot(
        id: bots[index].id,
        name: bots[index].name,
        username: bots[index].username,
        token: bots[index].token,
        ownerPublicKey: bots[index].ownerPublicKey,
        isActive: !bots[index].isActive,
        commands: bots[index].commands,
        welcomeMessage: bots[index].welcomeMessage,
        createdAt: bots[index].createdAt,
        totalMessages: bots[index].totalMessages,
      );
      await _saveBots(bots);
    }
  }

  // Удаление бота
  Future<void> deleteBot(String id) async {
    final bots = _getAllBots();
    bots.removeWhere((b) => b.id == id);
    await _saveBots(bots);
  }

  // Обновление сообщений бота
  Future<void> incrementMessages(String id) async {
    final bots = _getAllBots();
    final index = bots.indexWhere((b) => b.id == id);
    if (index != -1) {
      final bot = bots[index];
      bots[index] = VeilBot(
        id: bot.id,
        name: bot.name,
        username: bot.username,
        token: bot.token,
        ownerPublicKey: bot.ownerPublicKey,
        isActive: bot.isActive,
        commands: bot.commands,
        welcomeMessage: bot.welcomeMessage,
        createdAt: bot.createdAt,
        totalMessages: bot.totalMessages + 1,
      );
      await _saveBots(bots);
    }
  }

  // Получение всех ботов (для админа)
  List<VeilBot> getAllBots() {
    return _getAllBots();
  }

  // Приватные методы
  List<VeilBot> _getAllBots() {
    final raw = _botsBox.get('bots');
    if (raw is List) {
      return raw
          .where((item) => item is Map)
          .map((item) => VeilBot.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<void> _saveBots(List<VeilBot> bots) async {
    await _botsBox.put('bots', bots.map((b) => b.toJson()).toList());
  }
}