import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../auth/auth_repository.dart';
import '../theme/app_colors.dart';

/// FitPilot Auth-Screen. Editorial Komposition: Wordmark oben, zentrierte
/// Eyebrow-Headline mit serif-italic Kontrast-Wort, Underline-Inputs mit
/// zentriertem Text, Pill-Buttons, mono "ODER"-Divider. Single-Screen mit
/// _isRegister-Toggle (Form-Logik unveraendert).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

// Lokale Design-Tokens. Nutzen unsere Theme-Farben + ein paar extra
// Tones (dimmer Placeholder, solid Line) die nur hier auf der Auth-Page
// gebraucht werden.
const _line = Color(0xFF232327);
const _dim = Color(0xFF55555C);
const _ink = bg; // Text auf Lime-Pill

class _AuthScreenState extends State<AuthScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  bool _passwordVisible = false;
  FitPilotOAuthProvider? _oauthLoading;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _busy => _loading || _oauthLoading != null;

  Future<void> _startOAuth(FitPilotOAuthProvider provider) async {
    setState(() {
      _error = null;
      _message = null;
      _oauthLoading = provider;
    });
    try {
      await widget.authRepository.signInWithOAuth(provider);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _oauthLoading = null);
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    setState(() {
      _error = null;
      _message = null;
    });

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Bitte gib eine gültige E-Mail ein.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Das Passwort braucht mindestens 6 Zeichen.');
      return;
    }
    if (_isRegister && name.length < 2) {
      setState(() => _error = 'Wie dürfen wir dich nennen?');
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isRegister) {
        await widget.authRepository.signUp(
          email: email,
          password: password,
          displayName: name,
        );
        if (!mounted) return;
        setState(() => _message =
            'Bestätigungs-Mail unterwegs an $email. Klick den Link, dann bist du drin.');
      } else {
        await widget.authRepository.signIn(email: email, password: password);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('invalid login') || raw.contains('invalid credentials')) {
      return 'E-Mail oder Passwort stimmt nicht.';
    }
    if (raw.contains('already registered') || raw.contains('already exists')) {
      return 'Diese E-Mail ist schon registriert. Versuch Login.';
    }
    if (raw.contains('email not confirmed')) {
      return 'Bitte bestätige zuerst deine E-Mail.';
    }
    if (raw.contains('provider') && raw.contains('enabled')) {
      return 'Dieser Login-Anbieter ist in Supabase noch nicht aktiviert.';
    }
    if (raw.contains('redirect') || raw.contains('callback')) {
      return 'OAuth Redirect ist noch nicht korrekt eingetragen.';
    }
    if (raw.contains('cancel')) {
      return 'Login wurde abgebrochen.';
    }
    return 'Das hat gerade nicht geklappt. Bitte nochmal versuchen.';
  }

  void _setMode(bool register) {
    setState(() {
      _isRegister = register;
      _error = null;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('screen-auth'),
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const _Wordmark(),
                        const Spacer(),
                        _HeroHeadline(
                          eyebrow: _isRegister
                              ? 'KONTO ERSTELLEN'
                              : 'WILLKOMMEN ZURÜCK',
                          lineA: _isRegister ? 'Starte' : 'Bereit',
                          italic: _isRegister ? 'durch' : 'abzuheben',
                          lineB: _isRegister ? '.' : '?',
                        ),
                        const SizedBox(height: 32),
                        _EmailForm(
                          isRegister: _isRegister,
                          loading: _loading,
                          busy: _busy,
                          passwordVisible: _passwordVisible,
                          nameController: _nameController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          error: _error,
                          message: _message,
                          onTogglePassword: () => setState(
                            () => _passwordVisible = !_passwordVisible,
                          ),
                          onSubmit: _submit,
                        ),
                        const SizedBox(height: 22),
                        const _OrDivider(),
                        const SizedBox(height: 16),
                        _GoogleButton(
                          enabled: !_busy,
                          loading: _oauthLoading == FitPilotOAuthProvider.google,
                          onTap: () =>
                              _startOAuth(FitPilotOAuthProvider.google),
                        ),
                        const Spacer(),
                        const SizedBox(height: 16),
                        _ModeFooter(
                          isRegister: _isRegister,
                          onChanged: _setMode,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Wordmark — Paper-Plane Glyph in lime Kreis + Caps-Lock Wordmark
// ═════════════════════════════════════════════════════════════════════

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: lime,
            shape: BoxShape.circle,
          ),
          child: const CustomPaint(painter: _PaperPlanePainter()),
        ),
        const SizedBox(width: 10),
        const Text(
          'FITPILOT',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PaperPlanePainter extends CustomPainter {
  const _PaperPlanePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _ink
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.55)
      ..lineTo(size.width * 0.86, size.height * 0.18)
      ..lineTo(size.width * 0.62, size.height * 0.86)
      ..lineTo(size.width * 0.50, size.height * 0.62)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════
// Hero — Eyebrow mit Hairlines + serif-italic Kontrast-Wort
// ═════════════════════════════════════════════════════════════════════

class _HeroHeadline extends StatelessWidget {
  const _HeroHeadline({
    required this.eyebrow,
    required this.lineA,
    required this.italic,
    required this.lineB,
  });
  final String eyebrow, lineA, italic, lineB;

  @override
  Widget build(BuildContext context) {
    const size = 42.0;
    return Column(
      key: const ValueKey('auth-hero'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 20, height: 1, color: lime),
            const SizedBox(width: 10),
            Text(
              eyebrow,
              style: const TextStyle(
                fontFamily: 'Roboto Mono',
                fontSize: 10,
                color: lime,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 20, height: 1, color: lime),
          ],
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: size,
              height: 1.02,
              letterSpacing: -size * 0.03,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
            children: [
              TextSpan(text: '$lineA '),
              TextSpan(
                text: italic,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: size,
                  height: 1.02,
                  letterSpacing: -size * 0.03,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: textPrimary,
                ),
              ),
              TextSpan(text: lineB),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Underline-Field — Mono-Label, zentrierter Input, dünner Underline
// ═════════════════════════════════════════════════════════════════════

class _UnderlineField extends StatefulWidget {
  const _UnderlineField({
    required this.fieldKey,
    required this.label,
    required this.hint,
    required this.controller,
    this.enabled = true,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.trailing,
  });

  final Key fieldKey;
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  State<_UnderlineField> createState() => _UnderlineFieldState();
}

class _UnderlineFieldState extends State<_UnderlineField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Roboto Mono',
                  fontSize: 9,
                  color: textMuted,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: widget.fieldKey,
          controller: widget.controller,
          focusNode: _focus,
          enabled: widget.enabled,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onSubmitted: widget.onSubmitted,
          textAlign: TextAlign.center,
          cursorColor: lime,
          cursorWidth: 1.5,
          style: const TextStyle(
            fontSize: 17,
            color: textPrimary,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              fontSize: 17,
              color: _dim,
            ),
            isDense: true,
            filled: false,
            contentPadding: const EdgeInsets.only(bottom: 10),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _line, width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: lime, width: 1),
            ),
            disabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _line, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Email-Form — Name (nur Register), Email, Password mit Eye-Toggle,
// Inline Note bei Error/Message, Lime-Pill Submit
// ═════════════════════════════════════════════════════════════════════

class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.isRegister,
    required this.loading,
    required this.busy,
    required this.passwordVisible,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.error,
    required this.message,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final bool isRegister;
  final bool loading;
  final bool busy;
  final bool passwordVisible;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? error;
  final String? message;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('auth-email-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: isRegister
              ? Padding(
                  key: const ValueKey('name-field-wrap'),
                  padding: const EdgeInsets.only(bottom: 22),
                  child: _UnderlineField(
                    fieldKey: const ValueKey('auth-name-field'),
                    label: 'NAME',
                    hint: 'Dein Name',
                    controller: nameController,
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('no-name-field')),
        ),
        _UnderlineField(
          fieldKey: const ValueKey('auth-email-field'),
          label: 'E-MAIL',
          hint: 'du@beispiel.de',
          controller: emailController,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 22),
        _UnderlineField(
          fieldKey: const ValueKey('auth-password-field'),
          label: 'PASSWORT',
          hint: '••••••••',
          controller: passwordController,
          enabled: !busy,
          obscure: !passwordVisible,
          textInputAction: TextInputAction.done,
          autofillHints: isRegister
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.password],
          onSubmitted: (_) => busy ? null : onSubmit(),
          trailing: GestureDetector(
            key: const ValueKey('auth-toggle-password'),
            onTap: busy ? null : onTogglePassword,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                passwordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 16,
                color: textMuted,
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          _InlineNote(text: error!, isError: true),
        ],
        if (message != null) ...[
          const SizedBox(height: 16),
          _InlineNote(text: message!, isError: false),
        ],
        const SizedBox(height: 30),
        _LimePill(
          buttonKey: const ValueKey('auth-submit'),
          label: isRegister ? 'Account erstellen' : 'Einloggen',
          loading: loading,
          enabled: !busy,
          onTap: onSubmit,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Lime-Pill — Primary CTA, weiches Disabled-Surface
// ═════════════════════════════════════════════════════════════════════

class _LimePill extends StatelessWidget {
  const _LimePill({
    required this.buttonKey,
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled;
    return GestureDetector(
      key: buttonKey,
      onTap: disabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: disabled ? surface : lime,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: _ink,
                ),
              )
            else
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: disabled ? textMuted : _ink,
                  letterSpacing: -0.1,
                ),
              ),
            if (!loading) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 17,
                color: disabled ? textMuted : _ink,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Google-Button — Outlined Pill mit 4-Farb-G-Glyph
// ═════════════════════════════════════════════════════════════════════

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('auth-google-oauth'),
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          decoration: BoxDecoration(
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: loading
                    ? const CircularProgressIndicator(
                        strokeWidth: 2.2, color: textPrimary)
                    : const CustomPaint(painter: _GoogleGPainter()),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mit Google anmelden',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;
    const stroke = 2.6;

    void arc(double startDeg, double sweepDeg, Color color) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startDeg * math.pi / 180,
        sweepDeg * math.pi / 180,
        false,
        p,
      );
    }

    arc(-90, 90, const Color(0xFF4285F4));
    arc(0, 90, const Color(0xFF34A853));
    arc(90, 90, const Color(0xFFFBBC05));
    arc(180, 90, const Color(0xFFEA4335));

    final p = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(cx, cy - 1.3, r, 2.6), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════
// ODER-Divider — Mono Caps, hauchdünne Lines
// ═════════════════════════════════════════════════════════════════════

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(children: const [
      Expanded(child: Divider(color: _line, height: 1)),
      SizedBox(width: 12),
      Text(
        'ODER',
        style: TextStyle(
          fontFamily: 'Roboto Mono',
          fontSize: 9,
          color: _dim,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(width: 12),
      Expanded(child: Divider(color: _line, height: 1)),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════
// Inline-Note — kleine Status-Zeile fuer Error/Message
// ═════════════════════════════════════════════════════════════════════

class _InlineNote extends StatelessWidget {
  const _InlineNote({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? orange : lime;
    return Row(
      key: ValueKey(isError ? 'auth-error' : 'auth-message'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isError
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Footer — "Schon dabei? Anmelden" mit Underline-Action
// ═════════════════════════════════════════════════════════════════════

class _ModeFooter extends StatelessWidget {
  const _ModeFooter({required this.isRegister, required this.onChanged});

  final bool isRegister;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final lead = isRegister ? 'Schon dabei?' : 'Neu hier?';
    final cta = isRegister ? 'Anmelden' : 'Konto erstellen';
    final toggleKey = isRegister
        ? const ValueKey('auth-toggle-login')
        : const ValueKey('auth-toggle-register');
    return GestureDetector(
      key: toggleKey,
      onTap: () => onChanged(!isRegister),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 13.5,
              color: textMuted,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(text: '$lead  '),
              TextSpan(
                text: cta,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
