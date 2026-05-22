class CardRequestRecord {
  final int id;
  final String cardId;
  final String status;
  final String? decisionReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  const CardRequestRecord({
    required this.id,
    required this.cardId,
    required this.status,
    this.decisionReason,
    this.createdAt,
    this.reviewedAt,
  });

  factory CardRequestRecord.fromJson(Map<String, dynamic> json) {
    return CardRequestRecord(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      cardId: json['cardId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      decisionReason: json['decisionReason']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      reviewedAt: json['reviewedAt'] != null ? DateTime.tryParse(json['reviewedAt'].toString()) : null,
    );
  }
}
