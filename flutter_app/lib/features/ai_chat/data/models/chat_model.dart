class ChatMessageModel {
  final String role, content; final DateTime timestamp;
  const ChatMessageModel({required this.role, required this.content, required this.timestamp});
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
class ChatResponseModel {
  final String reply; final List<String> suggestedQuestions;
  const ChatResponseModel({required this.reply, required this.suggestedQuestions});
  factory ChatResponseModel.fromJson(Map<String, dynamic> j) => ChatResponseModel(
    reply: j['reply'] ?? '', suggestedQuestions: List<String>.from(j['suggested_questions'] ?? []),
  );
}
