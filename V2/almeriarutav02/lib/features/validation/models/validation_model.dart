class ValidationModel {
  final String id;
  final String ticketId;
  final String type;
  final DateTime date;
  final String line;
  final String busId;
  final bool isValid;
  final String message;

  ValidationModel({
    required this.id,
    required this.ticketId,
    required this.type,
    required this.date,
    required this.line,
    required this.busId,
    required this.isValid,
    required this.message,
  });
}