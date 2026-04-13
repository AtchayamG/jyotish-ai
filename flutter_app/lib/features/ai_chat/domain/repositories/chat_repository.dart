import '../../data/models/chat_model.dart';
abstract class ChatRepository { Future<ChatResponseModel> sendMessage(String msg, List<ChatMessageModel> history); }
