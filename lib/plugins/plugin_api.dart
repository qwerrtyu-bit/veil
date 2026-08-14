import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PluginAPI {
  static final PluginAPI _instance = PluginAPI._internal();
  factory PluginAPI() => _instance;
  PluginAPI._internal();

  final Map<String, List<Function>> _listeners = {};
  final Map<String, List<Function>> _commands = {};
  final Map<String, List<Function>> _lifecycles = {};

  void registerCommand(String name, Function handler) {
    if (!_commands.containsKey(name)) {
      _commands[name] = [];
    }
    _commands[name]!.add(handler);
  }

  void registerLifecycle(String name, Function handler) {
    if (!_lifecycles.containsKey(name)) {
      _lifecycles[name] = [];
    }
    _lifecycles[name]!.add(handler);
  }

  dynamic callCommand(String name, Map<String, dynamic> params) {
    if (_commands.containsKey(name)) {
      for (final handler in _commands[name]!) {
        try {
          return handler(params);
        } catch (e) {
          print('Ошибка выполнения команды $name: $e');
        }
      }
    }
    return {'error': 'Команда $name не найдена'};
  }

  void on(String event, Function callback) {
    if (!_listeners.containsKey(event)) {
      _listeners[event] = [];
    }
    _listeners[event]!.add(callback);
  }

  void emit(String event, dynamic data) {
    if (_listeners.containsKey(event)) {
      for (final callback in _listeners[event]!) {
        try {
          callback(data);
        } catch (e) {
          print('Ошибка в обработчике события $event: $e');
        }
      }
    }
  }

  Future<dynamic> storageGet(String key) async {
    final box = Hive.box('plugin_data');
    return box.get(key);
  }

  Future<void> storageSet(String key, dynamic value) async {
    final box = Hive.box('plugin_data');
    await box.put(key, value);
  }

  Future<void> storageDelete(String key) async {
    final box = Hive.box('plugin_data');
    await box.delete(key);
  }

  Future<void> sendMessage(String chatId, String text) async {
    print('Плагин отправляет сообщение в $chatId: $text');
    
    try {
      final box = Hive.box('messages');
      final messages = box.get(chatId, defaultValue: <Map>[]);
      final now = TimeOfDay.now();
      final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      
      final newMessage = {
        'text': text,
        'isMe': true,
        'time': time,
        'reactions': <String, List<String>>{},
        'isPinned': false,
        'isRead': true,
      };
      
      messages.add(newMessage);
      await box.put(chatId, messages);
      
      print('Сообщение сохранено в Hive для чата $chatId');
    } catch (e) {
      print('Ошибка отправки сообщения через плагин: $e');
    }
  }

  Future<dynamic> httpGet(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<dynamic> httpPost(String url, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}