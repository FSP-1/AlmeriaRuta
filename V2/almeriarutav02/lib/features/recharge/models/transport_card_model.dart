class RechargeHistory {
  final DateTime date;
  final double amount;

  RechargeHistory({
    required this.date,
    required this.amount,
  });
}

enum CardType {
  single,
  bonobus,
  monthly,
  free,
}

enum ExpirationType {
  none,
  monthly,
  schoolYear,
  birthday,
}

class TransportCardModel {
  final String id;
  final String name;
  final CardType type;
  double balance;
  DateTime? expirationDate;
  ExpirationType expirationType;
  final List<RechargeHistory> history;
  bool active;

  TransportCardModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.active,
    this.expirationDate,
    this.expirationType = ExpirationType.none,
    List<RechargeHistory>? history,
  }) : history = history ?? [];
}