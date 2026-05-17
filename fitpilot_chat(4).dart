// fitpilot_chat.dart
//
// Fitpilot — Coach
// A clean, minimal AI coach screen.
//
// Layout: large gradient greeting centered on white, pill composer pinned
// to the bottom with mic / camera / voice icons.
//
// Drop-in usage:
//   Navigator.of(context).push(
//     CupertinoPageRoute(builder: (_) => const FitpilotChatScreen()),
//   );

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// ENTRY POINT
// ---------------------------------------------------------------------------

void main() {
  runApp(const FitpilotChatApp());
}

class FitpilotChatApp extends StatelessWidget {
  const FitpilotChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'FitPilot',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: FpColors.gradientEnd,
        scaffoldBackgroundColor: FpColors.bg,
      ),
      home: FitpilotChatScreen(userName: 'Alex'),
    );
  }
}

// ---------------------------------------------------------------------------
// TOKENS — dark
// ---------------------------------------------------------------------------

class FpColors {
  static const Color bg = Color(0xFF0E1014);
  static const Color composer = Color(0xFF1A1D23);
  static const Color iconChip = Color(0xFF1F2229);
  static const Color stroke = Color(0xFF24272F);

  static const Color ink = Color(0xFFECEEF1);
  static const Color ink2 = Color(0xFFA0A6B0);
  static const Color mute = Color(0xFF6A707A);

  // Greeting gradient — slightly brightened for dark backgrounds.
  static const Color gradientStart = Color(0xFF6E97FF); // blue
  static const Color gradientEnd = Color(0xFFB57AE0); // purple

  // User bubble + chat surfaces.
  static const Color userBubble = Color(0xFF1F2229);
}

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------

enum Sender { user, coach }

class ChatMessage {
  final String id;
  final Sender sender;
  final String text;
  final DateTime time;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

// ---------------------------------------------------------------------------
// SCREEN
// ---------------------------------------------------------------------------

class FitpilotChatScreen extends StatefulWidget {
  final String userName;
  const FitpilotChatScreen({super.key, this.userName = 'Alex'});

  @override
  State<FitpilotChatScreen> createState() => _FitpilotChatScreenState();
}

class _FitpilotChatScreenState extends State<FitpilotChatScreen> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _thinking = false;
  String _draft = '';

  bool get _isEmpty => _messages.isEmpty && !_thinking;

  @override
  void initState() {
    super.initState();
    _input.addListener(() {
      if (_draft != _input.text) setState(() => _draft = _input.text);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 240,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(ChatMessage(
        id: 'u${_messages.length}',
        sender: Sender.user,
        text: text,
      ));
      _input.clear();
      _draft = '';
      _thinking = true;
    });
    _scrollToBottom();

    Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _messages.add(_reply(text));
      });
      _scrollToBottom();
    });
  }

  ChatMessage _reply(String userText) {
    final l = userText.toLowerCase();
    String text;
    if (l.contains('workout') || l.contains('training')) {
      text =
          "Hier ist dein Plan für heute:\n\n• Bench Press — 4×6\n• Incline DB Press — 3×10\n• Overhead Press — 4×8\n• Lateral Raise — 3×12\n\nGeschätzt 52 Minuten.";
    } else if (l.contains('essen') || l.contains('ernähr')) {
      text =
          "Du hast noch 720 kcal und 58 g Protein offen. Vorschlag:\n\n• 180 g Hähnchen\n• 120 g Reis\n• Brokkoli + 10 g Olivenöl";
    } else if (l.contains('recovery') || l.contains('schlaf')) {
      text =
          "Recovery Score: 82 / 100.\nSchlaf 7h 12m, HRV +6 ms.\nDu bist bereit für eine intensive Einheit.";
    } else {
      text =
          "Sag mir, woran du heute arbeiten möchtest — Training, Ernährung oder Recovery.";
    }
    return ChatMessage(
      id: 'c${_messages.length}',
      sender: Sender.coach,
      text: text,
    );
  }

  // -----------------------------------------------------------------
  // BUILD
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: FpColors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(onClose: () => Navigator.of(context).maybePop()),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _isEmpty
                    ? _Greeting(name: widget.userName)
                    : _Conversation(
                        controller: _scroll,
                        focus: _focus,
                        messages: _messages,
                        thinking: _thinking,
                      ),
              ),
            ),
            _Composer(
              controller: _input,
              focus: _focus,
              draft: _draft,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TOP BAR — minimal, just a centered title and close.
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          const Center(
            child: Text(
              'FitPilot-Coach',
              style: TextStyle(
                color: FpColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: FpColors.iconChip,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    size: 15,
                    color: FpColors.ink,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () {},
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: FpColors.iconChip,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.square_pencil,
                    size: 17,
                    color: FpColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GREETING — the centerpiece. Large gradient text greeting the user.
// ---------------------------------------------------------------------------

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  String get _timeGreeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'Guten Morgen';
    if (h < 17) return 'Hallo';
    return 'Guten Abend';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      key: const ValueKey('greeting'),
      alignment: const Alignment(0, -0.25),
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [FpColors.gradientStart, FpColors.gradientEnd],
        ).createShader(rect),
        child: Text(
          '$_timeGreeting, $name',
          style: const TextStyle(
            color: Colors.white, // overridden by ShaderMask
            fontSize: 36,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.8,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CONVERSATION
// ---------------------------------------------------------------------------

class _Conversation extends StatelessWidget {
  final ScrollController controller;
  final FocusNode focus;
  final List<ChatMessage> messages;
  final bool thinking;

  const _Conversation({
    required this.controller,
    required this.focus,
    required this.messages,
    required this.thinking,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('conversation'),
      onTap: () => focus.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        itemCount: messages.length + (thinking ? 1 : 0),
        itemBuilder: (context, i) {
          if (thinking && i == messages.length) {
            return const _ThinkingDots();
          }
          return _MessageView(message: messages[i]);
        },
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final ChatMessage message;
  const _MessageView({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == Sender.user;
    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 11),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                decoration: BoxDecoration(
                  color: FpColors.userBubble,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: FpColors.ink,
                    fontSize: 15.5,
                    height: 1.35,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Coach: no bubble, just plain text on white, with a small gradient dot.
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GradientDot(size: 8),
              const SizedBox(width: 8),
              const Text(
                'FitPilot-Coach',
                style: TextStyle(
                  color: FpColors.ink2,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.text,
            style: const TextStyle(
              color: FpColors.ink,
              fontSize: 15.5,
              height: 1.45,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientDot extends StatelessWidget {
  final double size;
  const _GradientDot({this.size = 8});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [FpColors.gradientStart, FpColors.gradientEnd],
        ),
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 4),
      child: Row(
        children: [
          const _GradientDot(size: 8),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final phase = (_c.value + i * 0.18) % 1.0;
                  final t = math.sin(phase * math.pi).abs();
                  return Padding(
                    padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: FpColors.ink2.withOpacity(0.3 + 0.55 * t),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// COMPOSER — pill-shaped, with mic / camera / voice icons.
// ---------------------------------------------------------------------------

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final String draft;
  final ValueChanged<String> onSend;

  const _Composer({
    required this.controller,
    required this.focus,
    required this.draft,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = draft.trim().isNotEmpty;
    return Container(
      decoration: const BoxDecoration(
        color: FpColors.bg,
        border: Border(
          top: BorderSide(color: FpColors.stroke, width: 0.6),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 52,
                maxHeight: 140,
              ),
              padding: const EdgeInsets.fromLTRB(20, 4, 6, 4),
              decoration: BoxDecoration(
                color: FpColors.composer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: controller,
                      focusNode: focus,
                      minLines: 1,
                      maxLines: 5,
                      cursorColor: FpColors.gradientEnd,
                      placeholder: 'Ask FitPilot-Coach',
                      placeholderStyle: const TextStyle(
                        color: FpColors.mute,
                        fontSize: 15.5,
                        letterSpacing: -0.1,
                      ),
                      style: const TextStyle(
                        color: FpColors.ink,
                        fontSize: 15.5,
                        height: 1.3,
                        letterSpacing: -0.1,
                      ),
                      decoration: const BoxDecoration(),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      onSubmitted: onSend,
                    ),
                  ),
                  if (!hasText) ...[
                    _ComposerIcon(
                      icon: CupertinoIcons.mic,
                      onTap: () => HapticFeedback.selectionClick(),
                    ),
                    const SizedBox(width: 4),
                    _ComposerIcon(
                      icon: CupertinoIcons.camera,
                      onTap: () => HapticFeedback.selectionClick(),
                    ),
                  ] else
                    _SendButton(onTap: () => onSend(controller.text)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _VoiceButton(onTap: () => HapticFeedback.lightImpact()),
        ],
      ),
    );
  }
}

class _ComposerIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ComposerIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 44,
        child: Icon(icon, color: FpColors.ink, size: 20),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [FpColors.gradientStart, FpColors.gradientEnd],
          ),
        ),
        child: const Icon(
          CupertinoIcons.arrow_up,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  final VoidCallback onTap;
  const _VoiceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: FpColors.iconChip,
          shape: BoxShape.circle,
          border: Border.all(color: FpColors.stroke, width: 0.6),
        ),
        child: const Center(
          child: _VoiceWaveform(),
        ),
      ),
    );
  }
}

class _VoiceWaveform extends StatelessWidget {
  const _VoiceWaveform();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 18,
      child: CustomPaint(painter: _WaveformPainter()),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FpColors.ink
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;

    // Heights chosen to mimic the screenshot: short / tall / mid / tall.
    final heights = [0.45, 0.95, 0.55, 1.0];
    final gap = size.width / (heights.length - 1);
    final cy = size.height / 2;

    for (var i = 0; i < heights.length; i++) {
      final x = i * gap;
      final h = heights[i] * size.height;
      canvas.drawLine(
        Offset(x, cy - h / 2),
        Offset(x, cy + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
