class CardRequestAdminRecord {
  final int id;
  final int userId;
  final String cardId;
  final String status;
  final String? decisionReason;
  final DateTime? createdAt;
  final Map<String, dynamic>? payload;

  const CardRequestAdminRecord({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.status,
    this.decisionReason,
    this.createdAt,
    this.payload,
  });

  factory CardRequestAdminRecord.fromJson(Map<String, dynamic> json) {
    return CardRequestAdminRecord(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      userId: json['userId'] is int ? json['userId'] as int : int.parse('${json['userId']}'),
      cardId: json['cardId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      decisionReason: json['decisionReason']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : null,
    );
  }
}
