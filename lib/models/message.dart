import 'package:uuid/uuid.dart';

enum MessageRole { user, assistant }

class Message {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isError;

  Message({
    String? id,
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.isError = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'timestamp': timestamp.toIso8601String(),
        'isError': isError,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        content: json['content'] as String,
        role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isError: json['isError'] as bool? ?? false,
      );
}
