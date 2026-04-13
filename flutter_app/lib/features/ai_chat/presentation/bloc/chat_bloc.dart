import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/chat_model.dart';
import '../../domain/usecases/send_message_usecase.dart';

abstract class ChatEvent extends Equatable { const ChatEvent(); @override List<Object?> get props => []; }
class SendMessage  extends ChatEvent { final String message; const SendMessage(this.message); @override List<Object?> get props => [message]; }
class ClearHistory extends ChatEvent { const ClearHistory(); }

abstract class ChatState extends Equatable { const ChatState(); @override List<Object?> get props => []; }
class ChatInitial  extends ChatState { const ChatInitial(); }
class ChatUpdated  extends ChatState {
  final List<ChatMessageModel> messages;
  final List<String> suggestions;
  final bool isLoading;
  const ChatUpdated({required this.messages, this.suggestions = const [], this.isLoading = false});
  ChatUpdated copyWith({List<ChatMessageModel>? messages, List<String>? suggestions, bool? isLoading}) =>
    ChatUpdated(messages: messages ?? this.messages, suggestions: suggestions ?? this.suggestions, isLoading: isLoading ?? this.isLoading);
  @override List<Object?> get props => [messages.length, isLoading];
}
class ChatError extends ChatState { final String msg; const ChatError(this.msg); @override List<Object?> get props => [msg]; }

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUseCase _uc;
  final List<ChatMessageModel> _history = [];
  ChatBloc(this._uc) : super(const ChatInitial()) {
    on<SendMessage>(_onSend);
    on<ClearHistory>(_onClear);
  }

  Future<void> _onSend(SendMessage e, Emitter<ChatState> emit) async {
    final userMsg = ChatMessageModel(role: 'user', content: e.message, timestamp: DateTime.now());
    _history.add(userMsg);
    emit(ChatUpdated(messages: List.from(_history), isLoading: true));
    try {
      final resp = await _uc(e.message, _history.sublist(0, _history.length - 1));
      final aiMsg = ChatMessageModel(role: 'assistant', content: resp.reply, timestamp: DateTime.now());
      _history.add(aiMsg);
      emit(ChatUpdated(messages: List.from(_history), suggestions: resp.suggestedQuestions, isLoading: false));
    } catch (err) {
      _history.removeLast();
      emit(ChatError(err.toString()));
    }
  }

  void _onClear(ClearHistory e, Emitter<ChatState> emit) { _history.clear(); emit(const ChatInitial()); }
}
