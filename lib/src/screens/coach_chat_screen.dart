import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/chat_message.dart';
import '../services/coach_chat_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';

/// Coach-Chat: Pro-User-Konversation mit dem Grok-basierten Fitness/
/// Ernaehrungs-Coach. 5 Anfragen pro Tag, Limit serverseitig erzwungen.
class CoachChatScreen extends StatefulWidget {
  const CoachChatScreen({super.key, required this.service});

  final CoachChatService? service;

  @override
  State<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends State<CoachChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  List<ChatMessage> _messages = const <ChatMessage>[];
  ChatQuotaSnapshot _quota = ChatQuotaSnapshot.unknown;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final svc = widget.service;
    if (svc == null) {
      setState(() {
        _loading = false;
        _error = 'Bitte erst einloggen, um den Coach zu nutzen.';
      });
      return;
    }
    final history = await svc.loadHistory();
    final quota = await svc.loadQuotaToday();
    if (!mounted) return;
    setState(() {
      _messages = history;
      _quota = quota;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final svc = widget.service;
    final text = _input.text.trim();
    if (svc == null || text.isEmpty || _sending) return;
    if (_quota.remaining <= 0) {
      setState(() => _error =
          'Tageslimit erreicht (${_quota.dailyLimit} Coach-Fragen pro Tag). Morgen geht\'s weiter.');
      return;
    }

    final userMsg = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      role: ChatRole.user,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages = [..._messages, userMsg];
      _input.clear();
      _sending = true;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());

    try {
      final res = await svc.send(text);
      if (!mounted) return;
      setState(() {
        _messages = [
          ..._messages,
          ChatMessage(
            id: 'local-r-${DateTime.now().microsecondsSinceEpoch}',
            role: ChatRole.assistant,
            content: res.reply,
            createdAt: DateTime.now(),
            refusal: res.refusal,
          ),
        ];
        if (res.remaining != null) {
          _quota = _quota.copyWith(
            remaining: res.remaining,
            used: _quota.dailyLimit - res.remaining!.clamp(0, _quota.dailyLimit),
          );
        }
        _sending = false;
      });
      HapticFeedback.lightImpact();
    } on CoachQuotaExceeded catch (e) {
      if (!mounted) return;
      setState(() {
        _quota = _quota.copyWith(remaining: 0, used: e.dailyLimit, dailyLimit: e.dailyLimit);
        _error = e.message;
        _sending = false;
      });
    } on CoachChatException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _sending = false;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    return Column(
      key: const ValueKey('screen-coach'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CoachHeader(quota: _quota, disabled: svc == null || _loading),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: lime),
                  ),
                )
              : _messages.isEmpty
                  ? const _EmptyState()
                  : _MessageList(
                      controller: _scroll,
                      messages: _messages,
                      sending: _sending,
                    ),
        ),
        if (_error != null) _ErrorBanner(text: _error!),
        const SizedBox(height: 8),
        _Composer(
          controller: _input,
          focus: _inputFocus,
          enabled: svc != null && !_sending && _quota.remaining > 0,
          remaining: _quota.remaining,
          onSubmit: _send,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
class _CoachHeader extends StatelessWidget {
  const _CoachHeader({required this.quota, required this.disabled});

  final ChatQuotaSnapshot quota;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [violet, cyan],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.bolt_rounded, size: 20, color: bg),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FitPilot Coach',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Training & Ernaehrung. Nichts sonst.',
                style: TextStyle(
                  color: textMuted, fontSize: 12, fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _QuotaBadge(
          key: const ValueKey('coach-quota'),
          remaining: quota.remaining,
          dailyLimit: quota.dailyLimit,
          disabled: disabled,
        ),
      ],
    );
  }
}

class _QuotaBadge extends StatelessWidget {
  const _QuotaBadge({
    super.key,
    required this.remaining,
    required this.dailyLimit,
    required this.disabled,
  });

  final int remaining;
  final int dailyLimit;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? textMuted
        : remaining <= 0
            ? orange
            : remaining <= 2
                ? cyan
                : lime;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flash_on_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$remaining/$dailyLimit',
            style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  static const _suggestions = <String>[
    'Wie strukturiere ich meine Trainingswoche fuer Muskelaufbau?',
    'Was kann ich heute Abend essen mit 600 kcal und viel Protein?',
    'Wie reduziere ich Muskelkater nach Beintraining?',
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('coach-empty'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Hi - ich bin dein Coach.',
            style: TextStyle(
              color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Frag mich was zu Training, Ernaehrung oder Regeneration. '
            'Ich beantworte 5 Fragen pro Tag.',
            style: TextStyle(
              color: textMuted, fontSize: 13, height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          for (final s in _suggestions) ...[
            _SuggestionChip(text: s),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: textPrimary, fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.controller,
    required this.messages,
    required this.sending,
  });

  final ScrollController controller;
  final List<ChatMessage> messages;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const ValueKey('coach-message-list'),
      controller: controller,
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemCount: messages.length + (sending ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == messages.length) return const _TypingBubble();
        return _Bubble(message: messages[i]);
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final bgColor = isUser ? lime : surface;
    final fgColor = isUser ? bg : textPrimary;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: isUser ? null : Border.all(color: hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUser && message.refusal)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 12, color: orange),
                      SizedBox(width: 4),
                      Text(
                        'Off-topic',
                        style: TextStyle(
                          color: orange, fontSize: 10.5,
                          fontWeight: FontWeight.w700, letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                message.content,
                style: TextStyle(
                  color: fgColor, fontSize: 14, height: 1.4,
                  fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hairline),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.6, color: textMuted),
            ),
            SizedBox(width: 10),
            Text(
              'Coach denkt nach...',
              style: TextStyle(color: textMuted, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: textPrimary, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focus,
    required this.enabled,
    required this.remaining,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool enabled;
  final int remaining;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const ValueKey('coach-input'),
                controller: controller,
                focusNode: focus,
                enabled: enabled,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(color: textPrimary, fontSize: 14),
                cursorColor: lime,
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintText: remaining <= 0
                      ? 'Limit fuer heute erreicht'
                      : 'Frag deinen Coach...',
                  hintStyle: const TextStyle(color: textMuted, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _SendButton(
              enabled: enabled,
              onTap: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: enabled ? lime : surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: const ValueKey('coach-send'),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40, height: 40,
            alignment: Alignment.center,
            child: Icon(
              Icons.arrow_upward_rounded,
              size: 20,
              color: enabled ? bg : textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
