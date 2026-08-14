class GiftCardRequest {
  final String id;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String publicKey;
  final double amount;
  final DateTime createdAt;
  final String status; // pending, active, completed, rejected
  final String? giftCardCode;
  final String? comment;

  GiftCardRequest({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.publicKey,
    required this.amount,
    required this.createdAt,
    this.status = 'pending', // <-- ПО УМОЛЧАНИЮ НА ПРОВЕРКЕ
    this.giftCardCode,
    this.comment,
  });

  String get fullName => '$firstName $lastName';

  factory GiftCardRequest.fromJson(Map<String, dynamic> json) {
    return GiftCardRequest(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      publicKey: json['publicKey'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'pending',
      giftCardCode: json['giftCardCode'] as String?,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'publicKey': publicKey,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'giftCardCode': giftCardCode,
      'comment': comment,
    };
  }
}