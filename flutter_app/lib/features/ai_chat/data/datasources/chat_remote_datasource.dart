import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_constants.dart';
import '../models/chat_model.dart';

abstract class ChatRemoteDataSource {
  Future<ChatResponseModel> sendMessage(
    String msg,
    List<ChatMessageModel> history, {
    Map<String, dynamic>? userContext,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient _c;
  ChatRemoteDataSourceImpl(this._c);

  @override
  Future<ChatResponseModel> sendMessage(
    String msg,
    List<ChatMessageModel> history, {
    Map<String, dynamic>? userContext,
  }) {
    final body = <String, dynamic>{
      'message': msg,
      'history': history.map((m) => m.toJson()).toList(),
    };
    if (userContext != null) body['user_birth_details'] = userContext;

    return _c.post(
      ApiConstants.aiChat,
      body: body,
      fromJson: ChatResponseModel.fromJson,
    );
  }
}
