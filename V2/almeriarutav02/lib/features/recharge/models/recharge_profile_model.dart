class RechargeCardOption {
  final String key;
  final String title;
  final String description;
  final String rechargeMode;
  final String ageGroup;
  final int? travelCount;

  const RechargeCardOption({
    required this.key,
    required this.title,
    required this.description,
    required this.rechargeMode,
    required this.ageGroup,
    this.travelCount,
  });
}

class RechargeProfileModel {
  final String cardKey;
  final String cardLabel;
  final String rechargeMode;
  final String? ageGroup;
  final int? travelCount;
  final String? paymentMethod;
  final double saldoBalance;
  final bool hasSaldoCard;
  final String cardState;
  final bool configured;

  const RechargeProfileModel({
    required this.cardKey,
    required this.cardLabel,
    required this.rechargeMode,
    required this.cardState,
    this.ageGroup,
    this.travelCount,
    this.paymentMethod,
    this.saldoBalance = 0,
    this.hasSaldoCard = false,
    this.configured = false,
  });

  factory RechargeProfileModel.fromJson(Map<String, dynamic> json) {
    return RechargeProfileModel(
      cardKey: json['cardKey']?.toString() ?? '',
      cardLabel: json['cardLabel']?.toString() ?? '',
      rechargeMode: json['rechargeMode']?.toString() ?? '',
      ageGroup: json['ageGroup']?.toString(),
      travelCount: json['travelCount'] is int
          ? json['travelCount'] as int
          : int.tryParse(json['travelCount']?.toString() ?? ''),
      paymentMethod: json['paymentMethod']?.toString(),
      saldoBalance: (json['saldoBalance'] is num)
          ? (json['saldoBalance'] as num).toDouble()
          : double.tryParse(json['saldoBalance']?.toString() ?? '') ?? 0,
      hasSaldoCard: json['hasSaldoCard'] == true,
      cardState: json['cardState']?.toString() ?? 'active',
      configured: json['configured'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardKey': cardKey,
      'cardLabel': cardLabel,
      'rechargeMode': rechargeMode,
      'ageGroup': ageGroup,
      'travelCount': travelCount,
      'paymentMethod': paymentMethod,
      'saldoBalance': saldoBalance,
      'hasSaldoCard': hasSaldoCard,
      'cardState': cardState,
      'configured': configured,
    };
  }
}
