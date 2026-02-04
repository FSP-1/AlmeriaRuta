class TicketModel {
  final String id;
  final String type; // Ticket / Tarjeta
  final int quantity;
  final DateTime purchaseDate;
  final double amount;
  final String status; // Activo / Usado

  TicketModel({
    required this.id,
    required this.type,
    required this.quantity,
    required this.purchaseDate,
    required this.amount,
    required this.status,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      type: json['type'],
      quantity: json['quantity'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      amount: json['amount'].toDouble(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'quantity': quantity,
      'purchaseDate': purchaseDate.toIso8601String(),
      'amount': amount,
      'status': status,
    };
  }

  TicketModel copyWith({
    String? id,
    String? type,
    int? quantity,
    DateTime? purchaseDate,
    double? amount,
    String? status,
  }) {
    return TicketModel(
      id: id ?? this.id,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
    );
  }
}