class Message {
  final int? id;
  final String content;
  final bool isUser;
  final DateTime createdAt;
  final String? emotionDetected;

  Message({
    this.id,
    required this.content,
    required this.isUser,
    required this.createdAt,
    this.emotionDetected,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      isUser: json['is_user'],
      createdAt: DateTime.parse(json['created_at']),
      emotionDetected: json['emotion_detected'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'created_at': createdAt.toIso8601String(),
      'emotion_detected': emotionDetected,
    };
  }
}
