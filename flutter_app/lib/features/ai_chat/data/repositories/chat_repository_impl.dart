import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/chat_model.dart';
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _ds; ChatRepositoryImpl(this._ds);
  @override Future<ChatResponseModel> sendMessage(String msg, List<ChatMessageModel> history) => _ds.sendMessage(msg, history);
}
