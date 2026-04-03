import '../../tickets/models/ticket_model.dart';

class UserNotification {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? payloadJson;
  final TicketModel? ticket;

  const UserNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.payloadJson,
    required this.ticket,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    final payload = json['payloadJson'];
    final payloadMap = payload is Map<String, dynamic>
        ? payload
        : payload is Map
            ? payload.cast<String, dynamic>()
            : null;
    final ticketJson = payloadMap?['ticket'];
    final ticket = ticketJson is Map<String, dynamic>
        ? TicketModel.fromJson(ticketJson)
        : ticketJson is Map
            ? TicketModel.fromJson(ticketJson.cast<String, dynamic>())
            : null;

    return UserNotification(
      id: int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      isRead: json['is_read'] == true || json['isRead'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      payloadJson: payloadMap,
      ticket: ticket,
    );
  }
}