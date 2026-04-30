import '../../data/models/chat_model.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository _r;
  SendMessageUseCase(this._r);

  Future<ChatResponseModel> call(
    String msg,
    List<ChatMessageModel> history, {
    Map<String, dynamic>? userContext,
  }) =>
      _r.sendMessage(msg, history, userContext: userContext);
}
