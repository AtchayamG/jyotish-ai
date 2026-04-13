// lib/features/ai_chat/presentation/pages/ai_chat_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../../data/models/chat_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/no_network_page.dart';
import '../../../../core/widgets/error_page.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});
  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final msg = text ?? _ctrl.text.trim();
    if (msg.isEmpty) return;
    _ctrl.clear();
    context.read<ChatBloc>().add(SendMessage(msg));
    _scrollToBottom();
  }

  void _scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) => NetworkGuard(
        child: Scaffold(
          backgroundColor: AppColors.ink,
          appBar: AppBar(
            backgroundColor: AppColors.ink2,
            title: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.violetDim,
                  border: Border.all(color: AppColors.violet.withOpacity(0.4)),
                ),
                child: const Center(
                    child: Text('✦',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.violetLight))),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Jyotish AI', style: AppTextStyles.displayXs),
                Text('Vedic Mode · Tamil ON',
                    style: AppTextStyles.bodyXs
                        .copyWith(color: AppColors.teal, fontSize: 10)),
              ]),
            ]),
            actions: [
              IconButton(
                icon:
                    const Icon(Icons.delete_outline, color: AppColors.textHint),
                onPressed: () =>
                    context.read<ChatBloc>().add(const ClearHistory()),
              ),
            ],
          ),
          body: Column(children: [
            Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatUpdated) _scrollToBottom();
              },
              builder: (context, state) {
                if (state is ChatInitial) return _buildWelcome();
                if (state is ChatUpdated) {
                  return Column(children: [
                    Expanded(
                        child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount:
                          state.messages.length + (state.isLoading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == state.messages.length && state.isLoading) {
                          return _TypingBubble();
                        }
                        return _ChatBubble(message: state.messages[i]);
                      },
                    )),
                    if (state.suggestions.isNotEmpty)
                      _Suggestions(state.suggestions, _send),
                  ]);
                }
                if (state is ChatError) {
                  return InlineError(
                    message: state.msg,
                    onRetry: () =>
                        context.read<ChatBloc>().add(const ClearHistory()),
                  );
                }
                return const SizedBox.shrink();
              },
            )),
            _InputBar(ctrl: _ctrl, onSend: _send),
          ]),
        ),
      );

  Widget _buildWelcome() => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.x3l),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: AppSpacing.x4l),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.violetDim,
              border: Border.all(color: AppColors.violet.withOpacity(0.4)),
            ),
            child: const Center(
                child: Text('✦',
                    style:
                        TextStyle(fontSize: 32, color: AppColors.violetLight))),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Namaskaram! 🙏', style: AppTextStyles.displaySm),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "I'm your Vedic astrology companion.\nAsk me anything about your cosmos.",
            style: AppTextStyles.bodySm.copyWith(height: 1.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('SUGGESTED QUESTIONS', style: AppTextStyles.sectionTag),
          const SizedBox(height: AppSpacing.md),
          for (final q in [
            'When will I get married? 💫',
            'What does my current dasha mean?',
            'Which gemstone should I wear?',
            'What are today\'s auspicious times?',
            'What remedies will help me?',
          ])
            GestureDetector(
              onTap: () => _send(q),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(q, style: AppTextStyles.bodyMd),
              ),
            ),
        ]),
      );
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isUser ? AppColors.goldDim : AppColors.surface2,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isUser ? AppRadius.lg : 4),
            bottomRight: Radius.circular(isUser ? 4 : AppRadius.lg),
          ),
          border: Border.all(
              color: isUser
                  ? AppColors.gold.withOpacity(0.25)
                  : AppColors.borderSubtle),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!isUser) ...[
            Text('Jyotish AI',
                style: AppTextStyles.labelSm
                    .copyWith(color: AppColors.gold, fontSize: 10)),
            const SizedBox(height: 3),
          ],
          Text(message.content,
              style: AppTextStyles.bodyMd.copyWith(height: 1.6)),
        ]),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            ...List.generate(3, (i) => _Dot(delay: i * 200)),
          ]),
        ),
      );
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _a = Tween<double>(begin: 0.3, end: 1).animate(_c);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FadeTransition(
          opacity: _a,
          child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  color: AppColors.gold, shape: BoxShape.circle)),
        ),
      );
}

class _Suggestions extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onTap;
  const _Suggestions(this.suggestions, this.onTap);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: suggestions
                  .map((s) => GestureDetector(
                        onTap: () => onTap(s),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.goldDim,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                                color: AppColors.gold.withOpacity(0.3)),
                          ),
                          child: Text(s,
                              style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.gold, fontSize: 11)),
                        ),
                      ))
                  .toList()),
        ),
      );
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final Function([String?]) onSend;
  const _InputBar({required this.ctrl, required this.onSend});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: AppColors.ink2,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                  child: TextField(
                controller: ctrl,
                style: AppTextStyles.bodyMd,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask the cosmos anything...',
                  hintStyle:
                      AppTextStyles.bodyMd.copyWith(color: AppColors.textHint),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: AppColors.borderSubtle)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: AppColors.borderSubtle)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: AppColors.gold, width: 1.5)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              )),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => onSend(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: AppColors.gold, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_upward_rounded,
                      color: AppColors.ink, size: 20),
                ),
              ),
            ])),
      );
}
