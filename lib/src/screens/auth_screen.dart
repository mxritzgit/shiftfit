import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../auth/auth_repository.dart';
import '../theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

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
        setState(() => _message = 'Account erstellt. Check ggf. dein Postfach.');
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
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 36,
                  maxWidth: 400,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      const _BrandHeader(),
                      const SizedBox(height: 36),
                      _OAuthSection(
                        oauthLoading: _oauthLoading,
                        busy: _busy,
                        onApple: () =>
                            _startOAuth(FitPilotOAuthProvider.apple),
                        onGoogle: () =>
                            _startOAuth(FitPilotOAuthProvider.google),
                      ),
                      const SizedBox(height: 22),
                      const _OrDivider(),
                      const SizedBox(height: 22),
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
                      const SizedBox(height: 18),
                      _ModeFooter(
                        isRegister: _isRegister,
                        onChanged: _setMode,
                      ),
                      const SizedBox(height: 6),
                    ],
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('auth-hero'),
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: lime,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: lime.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, color: bg, size: 32),
        ),
        const SizedBox(height: 18),
        const Text(
          'FitPilot',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Plan, Kalorien und Fortschritt.\nIn einer App.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textMuted,
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OAuthSection extends StatelessWidget {
  const _OAuthSection({
    required this.oauthLoading,
    required this.busy,
    required this.onApple,
    required this.onGoogle,
  });

  final FitPilotOAuthProvider? oauthLoading;
  final bool busy;
  final VoidCallback onApple;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProviderButton(
          keyValue: const ValueKey('auth-apple-oauth'),
          label: 'Mit Apple anmelden',
          icon: const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Icon(Icons.apple, color: Colors.black, size: 22),
          ),
          loading: oauthLoading == FitPilotOAuthProvider.apple,
          enabled: !busy,
          onTap: onApple,
        ),
        const SizedBox(height: 10),
        _ProviderButton(
          keyValue: const ValueKey('auth-google-oauth'),
          label: 'Mit Google anmelden',
          icon: const _GoogleGLogo(),
          loading: oauthLoading == FitPilotOAuthProvider.google,
          enabled: !busy,
          onTap: onGoogle,
        ),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.keyValue,
    required this.label,
    required this.icon,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final Key keyValue;
  final String label;
  final Widget icon;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: keyValue,
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onTap : null,
            child: SizedBox(
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : icon,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final stroke = r * 0.42;
    final ringRect = Rect.fromCircle(
      center: Offset(r, r),
      radius: r - stroke / 2,
    );

    double rad(double deg) => deg * math.pi / 180;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // 0° = east (3 o'clock), positive = clockwise (Flutter Canvas convention).
    // Gap from 335° back through 25° (50° gap on the right) - that's where the
    // inner blue bar exits the ring. Color rotation matches the official mark:
    //   Green  25° → 95°  (bottom-right quadrant)
    //   Yellow 95° → 185° (bottom-left)
    //   Red   185° → 285° (top-left arc)
    //   Blue  285° → 335° (top-right, ends just above the bar)
    canvas.drawArc(ringRect, rad(25), rad(70), false, ring..color = _green);
    canvas.drawArc(ringRect, rad(95), rad(90), false, ring..color = _yellow);
    canvas.drawArc(ringRect, rad(185), rad(100), false, ring..color = _red);
    canvas.drawArc(ringRect, rad(285), rad(50), false, ring..color = _blue);

    // Inner horizontal bar, blue, exits through the gap to the right.
    // Right edge sits flush against the inner ring radius; left edge stops
    // just past the vertical center to keep the classic G silhouette.
    final innerR = r - stroke;
    final barRect = Rect.fromLTRB(
      r - stroke * 0.15,
      r - stroke / 2,
      r + innerR,
      r + stroke / 2,
    );
    canvas.drawRect(barRect, Paint()..color = _blue);
  }

  @override
  bool shouldRepaint(covariant _GoogleGPainter oldDelegate) => false;
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: hairline, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'oder per E-Mail',
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: hairline, height: 1)),
      ],
    );
  }
}

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
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: isRegister
              ? Padding(
                  key: const ValueKey('name-field-wrap'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    key: const ValueKey('auth-name-field'),
                    controller: nameController,
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('no-name-field')),
        ),
        TextField(
          key: const ValueKey('auth-email-field'),
          controller: emailController,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'E-Mail',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('auth-password-field'),
          controller: passwordController,
          enabled: !busy,
          obscureText: !passwordVisible,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => busy ? null : onSubmit(),
          autofillHints: isRegister
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: 'Passwort',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              key: const ValueKey('auth-toggle-password'),
              onPressed: busy ? null : onTogglePassword,
              icon: Icon(
                passwordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: textMuted,
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          _InlineNote(text: error!, isError: true),
        ],
        if (message != null) ...[
          const SizedBox(height: 10),
          _InlineNote(text: message!, isError: false),
        ],
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: FilledButton(
            key: const ValueKey('auth-submit'),
            style: FilledButton.styleFrom(
              backgroundColor: lime,
              foregroundColor: bg,
              disabledBackgroundColor: lime.withValues(alpha: 0.4),
              disabledForegroundColor: bg.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            onPressed: busy ? null : onSubmit,
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: bg,
                    ),
                  )
                : Text(isRegister ? 'Account erstellen' : 'Einloggen'),
          ),
        ),
      ],
    );
  }
}

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
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeFooter extends StatelessWidget {
  const _ModeFooter({required this.isRegister, required this.onChanged});

  final bool isRegister;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final lead = isRegister ? 'Schon registriert?' : 'Noch keinen Account?';
    final cta = isRegister ? 'Einloggen' : 'Registrieren';
    final toggleKey = isRegister
        ? const ValueKey('auth-toggle-login')
        : const ValueKey('auth-toggle-register');
    return Center(
      child: InkWell(
        key: toggleKey,
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!isRegister),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(text: '$lead  '),
                TextSpan(
                  text: cta,
                  style: const TextStyle(
                    color: lime,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
