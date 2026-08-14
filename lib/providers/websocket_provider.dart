import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/websocket_service.dart';

final webSocketProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});