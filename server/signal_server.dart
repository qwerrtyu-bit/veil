import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🟢 Veil Server запущен на порту $port');

  final Map<String, List<DateTime>> _requestLog = {};
  final Map<String, List<Map<String, dynamic>>> _pendingMessages = {};
  final List<String> _blockedKeys = [];

  bool _checkRateLimit(String ip) {
    final now = DateTime.now();
    _requestLog[ip] ??= [];
    _requestLog[ip]!.removeWhere((t) => now.difference(t).inSeconds > 60);
    _requestLog[ip]!.add(now);
    return _requestLog[ip]!.length <= 300;
  }

  await for (final request in server) {
    final ip = request.connectionInfo?.remoteAddress.address ?? 'unknown';

    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.set('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      request.response.close();
      continue;
    }

    if (!_checkRateLimit(ip)) {
      request.response.statusCode = 429;
      request.response.write('Too Many Requests');
      request.response.close();
      continue;
    }

    final path = request.uri.path;

    if (path == '/ping') {
      request.response.write('pong');
    } else if (path == '/block') {
      final body = await utf8.decodeStream(request);
      final data = jsonDecode(body) as Map<String, dynamic>;
      final key = data['key'] as String;
      if (!_blockedKeys.contains(key)) {
        _blockedKeys.add(key);
        print('🚫 Ключ заблокирован: ${key.length > 8 ? key.substring(0, 8) : key}');
      }
      request.response.write(jsonEncode({'status': 'ok', 'blocked': _blockedKeys.length}));
    } else if (path == '/unblock') {
      final body = await utf8.decodeStream(request);
      final data = jsonDecode(body) as Map<String, dynamic>;
      final key = data['key'] as String;
      _blockedKeys.remove(key);
      print('✅ Ключ разблокирован: ${key.length > 8 ? key.substring(0, 8) : key}');
      request.response.write(jsonEncode({'status': 'ok', 'blocked': _blockedKeys.length}));
    } else if (path == '/blocked') {
      request.response.write(jsonEncode({'blocked': _blockedKeys}));
    } else if (path == '/plugins') {
      request.response.write(jsonEncode({
        'plugins': [
          {'id': '1', 'name': 'Тёмная тема Pro', 'author': 'void', 'type': 'theme', 'price': 'Бесплатно', 'description': 'Расширенная тёмная тема', 'downloads': 156, 'version': '1.0.0'},
          {'id': '2', 'name': 'Антиспам фильтр', 'author': '0xTima', 'type': 'filter', 'price': '299 ₽', 'description': 'Автоматическое удаление спама', 'downloads': 89, 'version': '2.1.0'},
          {'id': '3', 'name': 'Экспорт в PDF', 'author': 'user123', 'type': 'export', 'price': 'Бесплатно', 'description': 'Выгрузка чатов в PDF', 'downloads': 34, 'version': '1.0.0'},
        ]
      }));
    } else if (path == '/register') {
      final body = await utf8.decodeStream(request);
      final data = jsonDecode(body) as Map<String, dynamic>;
      final userId = data['userId'] as String;
      if (_blockedKeys.contains(userId)) {
        request.response.statusCode = 403;
        request.response.write(jsonEncode({'status': 'blocked', 'message': 'Ваш ключ заблокирован'}));
        print('🚫 Попытка входа заблокированного: ${userId.length > 8 ? userId.substring(0, 8) : userId}');
      } else {
        _pendingMessages[userId] ??= [];
        print('✅ Узел: ${userId.length > 8 ? userId.substring(0, 8) : userId}');
        request.response.write(jsonEncode({'status': 'ok', 'onlineCount': _pendingMessages.length}));
      }
    } else if (path == '/send') {
      final body = await utf8.decodeStream(request);
      final data = jsonDecode(body) as Map<String, dynamic>;
      final fromId = data['from'] as String?;
      if (fromId != null && _blockedKeys.contains(fromId)) {
        request.response.statusCode = 403;
        request.response.write(jsonEncode({'status': 'blocked'}));
      } else {
        final targetId = data['to'] as String?;
        if (targetId != null) {
          _pendingMessages[targetId] ??= [];
          _pendingMessages[targetId]!.add(data);
          print('📡 Сообщение для: ${targetId.length > 8 ? targetId.substring(0, 8) : targetId}');
        }
        request.response.write(jsonEncode({'status': 'ok'}));
      }
    } else if (path == '/poll') {
      final userId = request.uri.queryParameters['userId'] ?? '';
      final syncAll = request.uri.queryParameters['sync'] == 'true';
      if (_blockedKeys.contains(userId)) {
        request.response.write(jsonEncode({'messages': <Map<String, dynamic>>[], 'blocked': true}));
      } else {
        final messages = syncAll ? (_pendingMessages[userId] ?? []) : (_pendingMessages[userId] ?? []);
        _pendingMessages[userId] = [];
        request.response.write(jsonEncode({'messages': messages}));
      }
    } else {
      request.response.write('Veil Server OK');
    }
    request.response.close();
  }
}