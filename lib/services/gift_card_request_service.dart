import 'package:hive_flutter/hive_flutter.dart';
import '../models/gift_card_request.dart';
import 'dart:math';

class GiftCardRequestService {
  final Box _box = Hive.box('gift_requests');

  // === Заявки ===

  Future<void> submitRequest(GiftCardRequest request) async {
    final requests = _getAllRequests();
    requests.add(request);
    _saveRequests(requests);
  }

  List<GiftCardRequest> getAllRequests() {
    return _getAllRequests();
  }

  List<GiftCardRequest> getRequestsByKey(String publicKey) {
    return _getAllRequests().where((r) => r.publicKey == publicKey).toList();
  }

  Future<void> updateRequestStatus(
    String id,
    String status, {
    String? giftCardCode,
    String? comment,
  }) async {
    final requests = _getAllRequests();
    final index = requests.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final old = requests[index];
    final updated = GiftCardRequest(
      id: old.id,
      firstName: old.firstName,
      lastName: old.lastName,
      dateOfBirth: old.dateOfBirth,
      publicKey: old.publicKey,
      amount: old.amount,
      createdAt: old.createdAt,
      status: status,
      giftCardCode: giftCardCode ?? old.giftCardCode,
      comment: comment ?? old.comment,
    );

    requests[index] = updated;
    _saveRequests(requests);
  }

  void deleteRequest(String id) {
    final requests = _getAllRequests();
    requests.removeWhere((r) => r.id == id);
    _saveRequests(requests);
  }

  // === Подарочные карты ===

  String generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<GiftCardRequest> createGiftCard({
    required String recipientName,
    String? recipientKey,
    required double amount,
    required String accountNumber,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final code = generateCode();

    final card = GiftCardRequest(
      id: id,
      firstName: recipientName.split(' ')[0],
      lastName: recipientName.split(' ').length > 1 ? recipientName.split(' ')[1] : '',
      dateOfBirth: '01.01.2000',
      publicKey: recipientKey ?? '',
      amount: amount,
      createdAt: DateTime.now(),
      status: 'active',
      giftCardCode: code,
    );

    final cards = _getAllCards();
    cards.add(card);
    _saveCards(cards);

    return card;
  }

  Future<bool> activateCard(String code, String activatedBy) async {
    final cards = _getAllCards();
    final index = cards.indexWhere((c) =>
        c.giftCardCode == code &&
        c.status != 'activated' &&
        c.status != 'completed');

    if (index == -1) {
      return false;
    }

    final card = cards[index];
    final updated = GiftCardRequest(
      id: card.id,
      firstName: card.firstName,
      lastName: card.lastName,
      dateOfBirth: card.dateOfBirth,
      publicKey: card.publicKey,
      amount: card.amount,
      createdAt: card.createdAt,
      status: 'completed',
      giftCardCode: card.giftCardCode,
      comment: 'Активирована пользователем $activatedBy',
    );

    cards[index] = updated;
    _saveCards(cards);

    return true;
  }

  GiftCardRequest? getCardByCode(String code) {
    final cards = _getAllCards();
    try {
      return cards.firstWhere((c) =>
          c.giftCardCode == code &&
          c.status != 'activated' &&
          c.status != 'completed');
    } catch (_) {
      return null;
    }
  }

  List<GiftCardRequest> getAllCards() {
    return _getAllCards();
  }

  List<GiftCardRequest> getActiveCards() {
    return _getAllCards().where((c) => c.status == 'active').toList();
  }

  List<GiftCardRequest> getCompletedCards() {
    return _getAllCards().where((c) => c.status == 'completed').toList();
  }

  // ============================================================
  // ✅ НОВЫЕ МЕТОДЫ
  // ============================================================

  /// Получить активные или активированные карты (НЕ отклонённые)
  List<GiftCardRequest> getActiveOrCompletedCards() {
    return _getAllCards().where((c) => 
      c.status == 'active' || c.status == 'completed'
    ).toList();
  }

  /// Удалить все заявки
  void clearAllRequests() {
    _box.delete('requests');
  }

  /// Удалить все карты
  void clearAllCards() {
    _box.delete('cards');
  }

  /// Полная очистка всех данных
  void clearAllData() {
    _box.delete('requests');
    _box.delete('cards');
  }

  /// Удалить только отклонённые заявки
  void clearRejectedRequests() {
    final requests = _getAllRequests();
    final filtered = requests.where((r) => r.status != 'rejected').toList();
    _saveRequests(filtered);
  }

  /// Удалить карту по ID
  void deleteCard(String id) {
    final cards = _getAllCards();
    cards.removeWhere((c) => c.id == id);
    _saveCards(cards);
  }

  // === Приватные методы ===

  List<GiftCardRequest> _getAllRequests() {
    final raw = _box.get('requests');
    if (raw is List) {
      return raw
          .where((item) => item is Map)
          .map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return GiftCardRequest.fromJson(map);
          })
          .toList();
    }
    return [];
  }

  void _saveRequests(List<GiftCardRequest> requests) {
    _box.put('requests', requests.map((r) => r.toJson()).toList());
  }

  List<GiftCardRequest> _getAllCards() {
    final raw = _box.get('cards');
    if (raw is List) {
      return raw
          .where((item) => item is Map)
          .map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return GiftCardRequest.fromJson(map);
          })
          .toList();
    }
    return [];
  }

  void _saveCards(List<GiftCardRequest> cards) {
    _box.put('cards', cards.map((c) => c.toJson()).toList());
  }
}