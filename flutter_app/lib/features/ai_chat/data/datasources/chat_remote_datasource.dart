import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_constants.dart';
import '../models/chat_model.dart';

abstract class ChatRemoteDataSource {
  Future<ChatResponseModel> sendMessage(
    String msg,
    List<ChatMessageModel> history,
  );
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient _c;
  ChatRemoteDataSourceImpl(this._c);

  @override
  Future<ChatResponseModel> sendMessage(
    String msg,
    List<ChatMessageModel> history,
  ) {
    // Send only the message and last-10 history.
    // Birth chart is fetched server-side from the authenticated user's profile.
    // Auth token is automatically attached by TokenInterceptor.
    return _c.post(
      ApiConstants.aiChat,
      body: {
        'message': msg,
        'history': history.map((m) => m.toJson()).toList(),
      },
      fromJson: ChatResponseModel.fromJson,
    );
  }
}
