class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? insight;
  final List<String> suggestedQuestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.insight,
    this.suggestedQuestions = const [],
  });
}

class AiConversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
