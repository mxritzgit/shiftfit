import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../auth/auth_repository.dart';
import '../theme/app_colors.dart';

/// FitPilot Auth-Screen. Cleanes, professionelles Layout in der App-Bildsprache:
/// Lime-Badge + Wordmark, klare Headline/Subline, links-ausgerichtete Felder
/// mit Leading-Icon (auf surfaceSoft, abgerundet), Lime-Pill-CTA, Google-OAuth,
/// Mode-Footer. Single-Screen mit _isRegister-Toggle (Form-Logik unverändert).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

// Lokale Tokens: dimmer Placeholder + Text auf der Lime-Pill.
const _dim = Color(0xFF55555C);
const _ink = bg;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AuthHero(isRegister: _isRegister),
              const SizedBox(height: 30),
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
              const SizedBox(height: 18),
              _GoogleButton(
                enabled: !_busy,
                loading: _oauthLoading == FitPilotOAuthProvider.google,
                onTap: () => _startOAuth(FitPilotOAuthProvider.google),
              ),
              const SizedBox(height: 26),
              _ModeFooter(isRegister: _isRegister, onChanged: _setMode),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Hero — Lime-Badge mit Paper-Plane, Wordmark, Headline + Subline
// ═════════════════════════════════════════════════════════════════════

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.isRegister});

  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('auth-hero'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: lime,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: lime.withValues(alpha: 0.30),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CustomPaint(painter: _PaperPlanePainter()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'FitPilot',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          isRegister ? 'Konto erstellen' : 'Willkommen zurück',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.05,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isRegister
              ? 'Erstelle dein Konto und leg direkt los.'
              : 'Melde dich an, um weiterzumachen.',
          style: const TextStyle(
            color: textMuted,
            fontSize: 14.5,
            height: 1.4,
            fontWeight: FontWeight.w500,
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
// Auth-Field — boxed, links-ausgerichtet, Leading-Icon, Lime-Fokus
// ═════════════════════════════════════════════════════════════════════

class _AuthField extends StatefulWidget {
  const _AuthField({
    required this.fieldKey,
    required this.icon,
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
  final IconData icon;
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
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
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
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? lime : hairline,
          width: focused ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(widget.icon, size: 19, color: focused ? lime : textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: widget.fieldKey,
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              autofillHints: widget.autofillHints,
              onSubmitted: widget.onSubmitted,
              cursorColor: lime,
              cursorWidth: 1.6,
              style: const TextStyle(
                fontSize: 15.5,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 17),
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  fontSize: 15.5,
                  color: _dim,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Email-Form — Name (nur Register), Email, Passwort + Eye, Note, CTA
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
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AuthField(
                    fieldKey: const ValueKey('auth-name-field'),
                    icon: Icons.person_outline_rounded,
                    hint: 'Dein Name',
                    controller: nameController,
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('no-name-field')),
        ),
        _AuthField(
          fieldKey: const ValueKey('auth-email-field'),
          icon: Icons.alternate_email_rounded,
          hint: 'du@beispiel.de',
          controller: emailController,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 12),
        _AuthField(
          fieldKey: const ValueKey('auth-password-field'),
          icon: Icons.lock_outline_rounded,
          hint: 'Passwort',
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
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                passwordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 18,
                color: textMuted,
              ),
            ),
          ),
        ),
        if (!isRegister) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Mind. 6 Zeichen',
              style: TextStyle(
                color: textMuted.withValues(alpha: 0.7),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 14),
          _InlineNote(text: error!, isError: true),
        ],
        if (message != null) ...[
          const SizedBox(height: 14),
          _InlineNote(text: message!, isError: false),
        ],
        const SizedBox(height: 22),
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
// Lime-Pill — Primary CTA
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: lime.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
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
            else ...[
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: disabled ? textMuted : _ink,
                  letterSpacing: -0.1,
                ),
              ),
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
            color: surfaceSoft,
            border: Border.all(color: hairline),
            borderRadius: BorderRadius.circular(16),
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
                  fontWeight: FontWeight.w600,
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
// ODER-Divider
// ═════════════════════════════════════════════════════════════════════

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider(color: hairline, height: 1)),
      const SizedBox(width: 12),
      Text(
        'ODER',
        style: TextStyle(
          fontSize: 11,
          color: textMuted.withValues(alpha: 0.8),
          letterSpacing: 1.6,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Divider(color: hairline, height: 1)),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════
// Inline-Note — Status-Zeile für Error/Message
// ═════════════════════════════════════════════════════════════════════

class _InlineNote extends StatelessWidget {
  const _InlineNote({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? orange : lime;
    return Container(
      key: ValueKey(isError ? 'auth-error' : 'auth-message'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 9),
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
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Footer — Mode-Toggle
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
                  color: lime,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
