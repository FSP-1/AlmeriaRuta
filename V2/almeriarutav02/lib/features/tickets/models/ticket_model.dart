class TicketModel {
  final String id;
  final String type; // Ticket / Tarjeta
  final int quantity;
  int remainingUses; // Usos restantes
  final DateTime purchaseDate;
  final double amount;
  final String status; // Activo / Usado

  TicketModel({
    required this.id,
    required this.type,
    required this.quantity,
    int? remainingUses,
    required this.purchaseDate,
    required this.amount,
    required this.status,
  }) : remainingUses = remainingUses ?? quantity;

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      type: json['type'],
      quantity: json['quantity'],
      remainingUses: json['remainingUses'],
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
      'remainingUses': remainingUses,
      'purchaseDate': purchaseDate.toIso8601String(),
      'amount': amount,
      'status': status,
    };
  }

  TicketModel copyWith({
    String? id,
    String? type,
    int? quantity,
    int? remainingUses,
    DateTime? purchaseDate,
    double? amount,
    String? status,
  }) {
    return TicketModel(
      id: id ?? this.id,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      remainingUses: remainingUses ?? this.remainingUses,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
    );
  }
}