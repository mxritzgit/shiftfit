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
      if (!mounted) return;
      setState(() {
        _message = '${provider.displayName} Login geöffnet. Danach kommst du '
            'automatisch zurück zu FitPilot.';
      });
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
        setState(() {
          _message = 'Account erstellt. Falls Supabase E-Mail-Bestätigung '
              'aktiviert hat, check kurz dein Postfach.';
        });
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
      return 'OAuth Redirect ist noch nicht korrekt in Supabase eingetragen.';
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _AuthTopBar(),
                    const SizedBox(height: 16),
                    _BrandHero(isRegister: _isRegister),
                    const SizedBox(height: 18),
                    _SocialAuthPanel(
                      oauthLoading: _oauthLoading,
                      busy: _busy,
                      onApple: () => _startOAuth(FitPilotOAuthProvider.apple),
                      onGoogle: () => _startOAuth(FitPilotOAuthProvider.google),
                    ),
                    const SizedBox(height: 16),
                    _EmailAuthCard(
                      isRegister: _isRegister,
                      loading: _loading,
                      busy: _busy,
                      passwordVisible: _passwordVisible,
                      nameController: _nameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      onModeChanged: _setMode,
                      onTogglePassword: () => setState(
                        () => _passwordVisible = !_passwordVisible,
                      ),
                      onSubmit: _submit,
                    ),
                    const SizedBox(height: 12),
                    if (_error != null) _InlineMessage(text: _error!, isError: true),
                    if (_message != null) _InlineMessage(text: _message!, isError: false),
                    const SizedBox(height: 22),
                    const _SecurityNote(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: lime.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: lime.withValues(alpha: 0.18)),
          ),
          child: const Icon(Icons.bolt_rounded, color: lime, size: 25),
        ),
        const SizedBox(width: 10),
        const Text(
          'FitPilot',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: surfaceSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: hairline),
          ),
          child: const Text(
            'Secure Auth',
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero({required this.isRegister});

  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('auth-hero'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF202734), Color(0xFF11151C)],
        ),
        border: Border.all(color: hairline),
        boxShadow: [
          BoxShadow(
            color: lime.withValues(alpha: 0.07),
            blurRadius: 42,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -18,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lime.withValues(alpha: 0.09),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: hairline),
                ),
                child: const Text(
                  'Training. Food. Fortschritt.',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                isRegister ? 'Dein Fitness-\nCockpit wartet.' : 'Willkommen\nzurück.',
                style: const TextStyle(
                  fontSize: 38,
                  height: 0.96,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.7,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isRegister
                    ? 'Ein Account für deinen Plan, Kalorien und Fortschritt.'
                    : 'Schnell anmelden und direkt im Heute-Screen landen.',
                style: const TextStyle(color: textMuted, fontSize: 15, height: 1.35),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialAuthPanel extends StatelessWidget {
  const _SocialAuthPanel({
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
    return Container(
      key: const ValueKey('auth-oauth-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: hairline),
      ),
      child: Column(
        children: [
          _OAuthButton(
            keyValue: const ValueKey('auth-apple-oauth'),
            label: 'Mit Apple anmelden',
            foreground: Colors.black,
            background: Colors.white,
            icon: const Icon(Icons.apple, color: Colors.black, size: 22),
            loading: oauthLoading == FitPilotOAuthProvider.apple,
            enabled: !busy,
            onTap: onApple,
          ),
          const SizedBox(height: 10),
          _OAuthButton(
            keyValue: const ValueKey('auth-google-oauth'),
            label: 'Mit Google anmelden',
            foreground: textPrimary,
            background: surfaceSoft,
            icon: const _GoogleMark(),
            loading: oauthLoading == FitPilotOAuthProvider.google,
            enabled: !busy,
            onTap: onGoogle,
          ),
        ],
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({
    required this.keyValue,
    required this.label,
    required this.foreground,
    required this.background,
    required this.icon,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final Key keyValue;
  final String label;
  final Color foreground;
  final Color background;
  final Widget icon;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: keyValue,
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: hairline),
          ),
          child: Row(
            children: [
              loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: foreground,
                      ),
                    )
                  : icon,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
              const SizedBox(width: 34),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmailAuthCard extends StatelessWidget {
  const _EmailAuthCard({
    required this.isRegister,
    required this.loading,
    required this.busy,
    required this.passwordVisible,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onModeChanged,
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
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('auth-email-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Divider(color: hairline)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'oder per E-Mail',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: hairline)),
            ],
          ),
          const SizedBox(height: 14),
          _ModeSwitch(isRegister: isRegister, onChanged: onModeChanged),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isRegister
                ? Padding(
                    key: const ValueKey('name-field-wrap'),
                    padding: const EdgeInsets.only(bottom: 12),
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
          const SizedBox(height: 12),
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
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              key: const ValueKey('auth-submit'),
              onPressed: busy ? null : onSubmit,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isRegister
                          ? Icons.arrow_forward_rounded
                          : Icons.login_rounded,
                    ),
              label: Text(isRegister ? 'Account erstellen' : 'Einloggen'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.isRegister, required this.onChanged});

  final bool isRegister;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              keyValue: const ValueKey('auth-toggle-login'),
              label: 'Login',
              selected: !isRegister,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ModeButton(
              keyValue: const ValueKey('auth-toggle-register'),
              label: 'Registrieren',
              selected: isRegister,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.keyValue,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key keyValue;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: keyValue,
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? lime : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? bg : textMuted,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? orange : lime;
    return Container(
      key: ValueKey(isError ? 'auth-error' : 'auth-message'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, height: 1.3),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'OAuth läuft über Supabase. FitPilot speichert keine Apple- oder Google-Passwörter.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
