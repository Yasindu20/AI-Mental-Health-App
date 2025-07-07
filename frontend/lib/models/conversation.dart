import 'message.dart';

class Conversation {
  final int id;
  final String mode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.messages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      mode: json['mode'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isActive: json['is_active'],
      messages:
          (json['messages'] as List?)
              ?.map((m) => Message.fromJson(m))
              .toList() ??
          [],
    );
  }
}
