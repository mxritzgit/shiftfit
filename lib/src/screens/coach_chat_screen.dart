import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../services/coach_chat_service.dart';
import '../theme/app_colors.dart';

/// Coach-Chat: Grok-basierter Fitness-/Ernaehrungs-Coach.
///
/// Text, Sprache und Bilder laufen weiter ueber die Supabase Edge Function.
/// Provider-Secrets bleiben damit serverseitig; der Client schickt nur die
/// User-Eingabe plus optional komprimiertes Bild.
class CoachChatScreen extends StatefulWidget {
  const CoachChatScreen({
    super.key,
    required this.service,
    this.userName = 'Moritz',
    this.imagePicker,
    this.speechInput = const CoachSpeechInput(),
  });

  final CoachChatService? service;
  final String userName;
  final ImagePicker? imagePicker;
  final CoachSpeechInput speechInput;

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
  bool _listening = false;
  String _draft = '';
  String? _error;

  ImagePicker get _picker => widget.imagePicker ?? ImagePicker();
  bool get _canInteract =>
      widget.service != null && !_loading && !_sending && _quota.remaining > 0;

  @override
  void initState() {
    super.initState();
    _input.addListener(() {
      if (_draft != _input.text) setState(() => _draft = _input.text);
    });
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
      _scroll.position.maxScrollExtent + 180,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _send({
    String? textOverride,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    final svc = widget.service;
    final typedText = textOverride ?? _input.text;
    final text = typedText.trim();
    final hasImage = imageBytes != null && imageBytes.isNotEmpty;
    if (svc == null || _sending || (text.isEmpty && !hasImage)) return;
    if (_quota.remaining <= 0) {
      setState(() => _error =
          'Tageslimit erreicht (${_quota.dailyLimit} Coach-Fragen pro Tag). Morgen geht\'s weiter.');
      return;
    }

    final displayText = text.isEmpty
        ? 'Analysiere dieses Bild im Fitness-Kontext.'
        : text;
    final userMsg = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      role: ChatRole.user,
      content: displayText,
      createdAt: DateTime.now(),
      imageBytes: imageBytes,
      mediaLabel: hasImage ? 'Bild' : null,
    );

    setState(() {
      _messages = [..._messages, userMsg];
      _input.clear();
      _draft = '';
      _sending = true;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());

    try {
      final res = await svc.send(
        displayText,
        imageBase64: hasImage ? base64Encode(imageBytes) : null,
        imageMimeType: hasImage ? (imageMimeType ?? 'image/jpeg') : null,
      );
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
        _quota = _quota.copyWith(
          remaining: 0,
          used: e.dailyLimit,
          dailyLimit: e.dailyLimit,
        );
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

  Future<void> _pickAndSendImage(ImageSource source) async {
    if (!_canInteract) return;
    HapticFeedback.selectionClick();
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      await _send(
        textOverride: _input.text.trim().isEmpty
            ? 'Analysiere dieses Bild im Fitness-Kontext.'
            : _input.text.trim(),
        imageBytes: bytes,
        imageMimeType: _mimeTypeFor(image),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _error = _permissionMessageFor(source, e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Das Bild konnte nicht geladen werden.');
    }
  }

  String _mimeTypeFor(XFile file) {
    final mime = file.mimeType?.toLowerCase();
    if (mime == 'image/png' || mime == 'image/webp' || mime == 'image/jpeg') {
      return mime!;
    }
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _permissionMessageFor(ImageSource source, PlatformException e) {
    final permissionText = source == ImageSource.camera
        ? 'Kamerazugriff'
        : 'Fotozugriff';
    final lower = '${e.code} ${e.message}'.toLowerCase();
    if (lower.contains('denied') || lower.contains('permission')) {
      return '$permissionText wurde nicht erlaubt. Du kannst die Berechtigung in den iOS-Einstellungen wieder aktivieren.';
    }
    return 'Das Bild konnte nicht geoeffnet werden.';
  }

  Future<void> _toggleSpeechInput() async {
    if (!_canInteract) return;
    HapticFeedback.selectionClick();
    if (_listening) {
      await widget.speechInput.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    setState(() {
      _listening = true;
      _error = null;
    });
    try {
      final spokenText = await widget.speechInput.listen(localeId: 'de_DE');
      if (!mounted) return;
      setState(() => _listening = false);
      final text = spokenText?.trim() ?? '';
      if (text.isEmpty) {
        setState(() => _error = 'Ich habe nichts verstanden. Versuch es nochmal.');
        return;
      }
      _input.text = text;
      await _send(textOverride: text);
    } on CoachSpeechException catch (e) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _error = 'Spracherkennung ist auf diesem Geraet gerade nicht verfuegbar.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    return Column(
      key: const ValueKey('screen-coach'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CoachHeader(
          quota: _quota,
          disabled: svc == null || _loading,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: lime),
                  ),
                )
              : _messages.isEmpty
                  ? _EmptyState(name: widget.userName)
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
          enabled: _canInteract,
          remaining: _quota.remaining,
          draft: _draft,
          listening: _listening,
          onSubmit: () => _send(),
          onMic: _toggleSpeechInput,
          onGallery: () => _pickAndSendImage(ImageSource.gallery),
          onCamera: () => _pickAndSendImage(ImageSource.camera),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
class CoachSpeechInput {
  const CoachSpeechInput();

  static const MethodChannel _channel = MethodChannel('fitpilot/speech');

  Future<String?> listen({String localeId = 'de_DE'}) async {
    try {
      return await _channel.invokeMethod<String>('listen', <String, dynamic>{
        'localeId': localeId,
      });
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('permission') || code.contains('denied')) {
        throw const CoachSpeechException(
          'Mikrofon oder Spracherkennung wurde nicht erlaubt. Du kannst die Berechtigung in den iOS-Einstellungen wieder aktivieren.',
        );
      }
      if (code.contains('unavailable')) {
        throw const CoachSpeechException(
          'Spracherkennung ist auf diesem Geraet gerade nicht verfuegbar.',
        );
      }
      throw CoachSpeechException(e.message ?? 'Spracherkennung fehlgeschlagen.');
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {
      // Stop ist best-effort; die laufende listen()-Future liefert sonst den
      // letzten erkannten Text oder laeuft mit ihrem eigenen Fehler aus.
    }
  }
}

class CoachSpeechException implements Exception {
  const CoachSpeechException(this.message);
  final String message;
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [violet, cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.auto_awesome_rounded, size: 20, color: bg),
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
                'Training, Ernaehrung, Regeneration',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
        borderRadius: BorderRadius.circular(12),
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
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.name});
  final String name;

  String get _timeGreeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'Gute Nacht';
    if (h < 11) return 'Guten Morgen';
    if (h < 17) return 'Guten Tag';
    return 'Guten Abend';
  }

  String get _firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Champion';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('coach-empty'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GradientText(
              '$_timeGreeting, $_firstName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                letterSpacing: -1.0,
                height: 1.06,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Frag per Text, Sprache oder Bild. Ich bleibe bei Fitness, Essen und Recovery.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textMuted, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 18),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _PromptPill('Workout planen'),
                _PromptPill('Makros checken'),
                _PromptPill('Form/Bild analysieren'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptPill extends StatelessWidget {
  const _PromptPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: hairline),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText(
    this.text, {
    required this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [cyan, violet, pink],
      ).createShader(rect),
      child: Text(text, textAlign: textAlign, style: style),
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
    final bgColor = isUser ? surfaceSoft : surface;
    final fgColor = textPrimary;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final imageBytes = message.imageBytes;
    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(14, imageBytes == null ? 10 : 8, 14, 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 5),
              bottomRight: Radius.circular(isUser ? 5 : 18),
            ),
            border: Border.all(
              color: isUser ? lime.withValues(alpha: 0.18) : hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    imageBytes,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (!isUser && message.refusal)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 12, color: orange),
                      SizedBox(width: 4),
                      Text(
                        'Hinweis',
                        style: TextStyle(
                          color: orange,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                message.content,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 14,
                  height: 1.42,
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

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _GradientDot(size: 8),
            const SizedBox(width: 9),
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final phase = (_controller.value + i * 0.18) % 1.0;
                  final t = math.sin(phase * math.pi).abs();
                  return Padding(
                    padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: textMuted.withValues(alpha: 0.28 + 0.55 * t),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientDot extends StatelessWidget {
  const _GradientDot({this.size = 8});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [cyan, violet]),
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
        borderRadius: BorderRadius.circular(14),
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
    required this.draft,
    required this.listening,
    required this.onSubmit,
    required this.onMic,
    required this.onGallery,
    required this.onCamera,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool enabled;
  final int remaining;
  final String draft;
  final bool listening;
  final VoidCallback onSubmit;
  final VoidCallback onMic;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final hasText = draft.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(30),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  hintText: remaining <= 0
                      ? 'Limit fuer heute erreicht'
                      : listening
                          ? 'Ich hoere zu...'
                          : 'Frag deinen Coach...',
                  hintStyle: const TextStyle(color: textMuted, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (!hasText) ...[
              _ComposerIcon(
                key: const ValueKey('coach-mic'),
                icon: Icons.mic_rounded,
                enabled: enabled,
                active: listening,
                onTap: onMic,
              ),
              _ComposerIcon(
                key: const ValueKey('coach-gallery'),
                icon: Icons.photo_rounded,
                enabled: enabled,
                onTap: onGallery,
              ),
              _ComposerIcon(
                key: const ValueKey('coach-camera'),
                icon: Icons.photo_camera_rounded,
                enabled: enabled,
                onTap: onCamera,
              ),
            ],
            _SendButton(
              enabled: enabled && hasText,
              onTap: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerIcon extends StatelessWidget {
  const _ComposerIcon({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? lime : (enabled ? textPrimary : textMuted);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? lime.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            width: 38,
            height: 42,
            child: Icon(icon, color: color, size: 19),
          ),
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
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          key: const ValueKey('coach-send'),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 40,
            height: 40,
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
