class CardRequestSubmission {
  final String cardId;
  final String fullName;
  final String dni;
  final String email;
  final String phone;
  final String address;
  final String extraNotes;
  final List<String> documentsProvided;
  final DateTime createdAt;

  const CardRequestSubmission({
    required this.cardId,
    required this.fullName,
    required this.dni,
    required this.email,
    required this.phone,
    required this.address,
    required this.extraNotes,
    required this.documentsProvided,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'fullName': fullName,
        'dni': dni,
        'email': email,
        'phone': phone,
        'address': address,
        'extraNotes': extraNotes,
        'documentsProvided': documentsProvided,
        'createdAt': createdAt.toIso8601String(),
      };
}
