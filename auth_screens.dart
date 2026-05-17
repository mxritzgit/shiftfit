// auth_screens.dart — FitPilot Login & Register (standalone)
//
// Eine einzige Datei. Keine externen Packages, keine Imports aus main.dart.
// Nutzung:
//   import 'auth_screens.dart';
//   runApp(const MaterialApp(home: AuthFlow(), debugShowCheckedModeBanner: false));
//
// Oder direkt als App ausführen:
//   void main() => runApp(const FitPilotAuthApp());

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────

class _K {
  static const bg = Color(0xFF0B0B0C);
  static const surface = Color(0xFF141416);
  static const line = Color(0xFF232327);
  static const fg = Color(0xFFF5F3EE);
  static const muted = Color(0xFF8A8A92);
  static const dim = Color(0xFF55555C);
  static const accent = Color(0xFFCCFF00);
  static const accentInk = Color(0xFF0B0B0C);

  static const fontFamily =
      'Inter, Roboto, -apple-system, BlinkMacSystemFont, sans-serif';
  static const serifFamily = 'Georgia, serif';
  static const monoFamily =
      'JetBrains Mono, SFMono-Regular, Consolas, monospace';

  static TextStyle display(double size,
          {Color? color,
          double height = 1.0,
          FontStyle? style,
          FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: height,
        letterSpacing: -size * 0.03,
        fontWeight: weight,
        fontStyle: style,
        color: color ?? fg,
      );

  static TextStyle body(double size,
          {Color? color,
          FontWeight weight = FontWeight.w400,
          double height = 1.5}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: height,
        fontWeight: weight,
        color: color ?? fg,
      );

  static TextStyle mono(double size,
          {Color? color,
          FontWeight weight = FontWeight.w500,
          double letterSpacing = 1.6}) =>
      TextStyle(
        fontFamily: monoFamily,
        fontSize: size,
        letterSpacing: letterSpacing,
        fontWeight: weight,
        color: color ?? fg,
      );
}

// ─────────────────────────────────────────────────────────────────────
// Optional: Standalone-App, falls du diese Datei direkt ausführen willst
// ─────────────────────────────────────────────────────────────────────

class FitPilotAuthApp extends StatelessWidget {
  const FitPilotAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitPilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: _K.bg,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          surface: _K.bg,
          primary: _K.accent,
          onPrimary: _K.accentInk,
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      home: const AuthFlow(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// AUTH FLOW — wechselt zwischen Login und Register
// ─────────────────────────────────────────────────────────────────────

enum AuthScreen { login, register }

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key, this.initial = AuthScreen.login});
  final AuthScreen initial;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  late AuthScreen _screen = widget.initial;
  void _go(AuthScreen s) => setState(() => _screen = s);

  @override
  Widget build(BuildContext context) {
    final child = _screen == AuthScreen.login
        ? LoginScreen(onRegister: () => _go(AuthScreen.register))
        : RegisterScreen(onLogin: () => _go(AuthScreen.login));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
      child: KeyedSubtree(key: ValueKey(_screen), child: child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// LOGIN
// ─────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onRegister});
  final VoidCallback? onRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      headline: const _HeroHeadline(
        eyebrow: 'WILLKOMMEN ZURÜCK',
        lineA: 'Bereit',
        italic: 'abzuheben',
        lineB: '?',
      ),
      fields: [
        _UnderlineField(
          label: 'E-MAIL',
          hint: 'du@beispiel.de',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        _UnderlineField(
          label: 'PASSWORT',
          hint: '••••••••',
          controller: _password,
          obscure: true,
          autofillHints: const [AutofillHints.password],
          trailing: GestureDetector(
            onTap: () {},
            child: Text(
              'VERGESSEN?',
              style: _K.mono(9,
                  color: _K.accent,
                  letterSpacing: 1.6,
                  weight: FontWeight.w600),
            ),
          ),
        ),
      ],
      primaryLabel: 'Anmelden',
      googleLabel: 'Mit Google anmelden',
      footerLead: 'Neu hier?',
      footerAction: 'Konto erstellen',
      onFooter: widget.onRegister ?? () {},
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// REGISTER
// ─────────────────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.onLogin});
  final VoidCallback? onLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      headline: const _HeroHeadline(
        eyebrow: 'KONTO ERSTELLEN',
        lineA: 'Starte',
        italic: 'durch',
        lineB: '.',
      ),
      fields: [
        _UnderlineField(
          label: 'NAME',
          hint: 'Dein Name',
          controller: _name,
          autofillHints: const [AutofillHints.name],
        ),
        _UnderlineField(
          label: 'E-MAIL',
          hint: 'du@beispiel.de',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        _UnderlineField(
          label: 'PASSWORT',
          hint: 'Mind. 8 Zeichen',
          controller: _password,
          obscure: true,
          autofillHints: const [AutofillHints.newPassword],
        ),
      ],
      primaryLabel: 'Konto erstellen',
      googleLabel: 'Mit Google fortfahren',
      footerLead: 'Schon dabei?',
      footerAction: 'Anmelden',
      onFooter: widget.onLogin ?? () {},
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Shared scaffold — zentriertes Layout
// ═════════════════════════════════════════════════════════════════════

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.headline,
    required this.fields,
    required this.primaryLabel,
    required this.googleLabel,
    required this.footerLead,
    required this.footerAction,
    required this.onFooter,
  });

  final Widget headline;
  final List<Widget> fields;
  final String primaryLabel, googleLabel;
  final String footerLead, footerAction;
  final VoidCallback onFooter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _K.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const _Wordmark(),
                        const Spacer(),
                        headline,
                        const SizedBox(height: 36),
                        for (var i = 0; i < fields.length; i++) ...[
                          if (i > 0) const SizedBox(height: 24),
                          fields[i],
                        ],
                        const SizedBox(height: 30),
                        _LimeButton(label: primaryLabel, onTap: () {}),
                        const SizedBox(height: 22),
                        const _OrDivider(),
                        const SizedBox(height: 16),
                        _GoogleButton(label: googleLabel, onTap: () {}),
                        const Spacer(),
                        const SizedBox(height: 16),
                        _FooterSwap(
                          lead: footerLead,
                          action: footerAction,
                          onTap: onFooter,
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
// Brand wordmark
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
            color: _K.accent,
            shape: BoxShape.circle,
          ),
          child: const _PilotGlyph(),
        ),
        const SizedBox(width: 10),
        Text(
          'FITPILOT',
          style: _K
              .body(12.5, weight: FontWeight.w700)
              .copyWith(letterSpacing: 1.8),
        ),
      ],
    );
  }
}

class _PilotGlyph extends StatelessWidget {
  const _PilotGlyph();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PaperPlane(), size: const Size(18, 18));
}

class _PaperPlane extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _K.accentInk
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
// Headline mit Eyebrow + Italic
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
    const size = 44.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 20, height: 1, color: _K.accent),
            const SizedBox(width: 10),
            Text(eyebrow,
                style: _K.mono(10, color: _K.accent, letterSpacing: 2)),
            const SizedBox(width: 10),
            Container(width: 20, height: 1, color: _K.accent),
          ],
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: _K.display(size, height: 1.02, weight: FontWeight.w500),
            children: [
              TextSpan(text: '$lineA '),
              TextSpan(
                text: italic,
                style: _K
                    .display(size,
                        height: 1.02,
                        weight: FontWeight.w400,
                        style: FontStyle.italic)
                    .copyWith(fontFamily: _K.serifFamily),
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
// Underline-Eingabefeld (zentrierter Text)
// ═════════════════════════════════════════════════════════════════════

class _UnderlineField extends StatefulWidget {
  const _UnderlineField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.trailing,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
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
              child: Text(widget.label,
                  style: _K.mono(9, color: _K.muted, letterSpacing: 1.6)),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          textAlign: TextAlign.center,
          cursorColor: _K.accent,
          cursorWidth: 1.5,
          style: _K.body(17, color: _K.fg),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: _K.body(17, color: _K.dim),
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 12),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _K.line, width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _K.accent, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Buttons
// ═════════════════════════════════════════════════════════════════════

class _LimeButton extends StatefulWidget {
  const _LimeButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  State<_LimeButton> createState() => _LimeButtonState();
}

class _LimeButtonState extends State<_LimeButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return MouseRegion(
      cursor: disabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            color: disabled
                ? _K.surface
                : (_hover ? _K.fg : _K.accent),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.label,
                  style: _K.body(15,
                      color: disabled ? _K.muted : _K.accentInk,
                      weight: FontWeight.w600)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward,
                  size: 17,
                  color: disabled ? _K.muted : _K.accentInk),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        decoration: BoxDecoration(
          border: Border.all(color: _K.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 18, height: 18, child: _GoogleGlyph()),
            const SizedBox(width: 12),
            Text(label,
                style: _K.body(14.5, color: _K.fg, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GooglePainter(), size: const Size(18, 18));
}

class _GooglePainter extends CustomPainter {
  // Stilisierter 4-Farb-Ring.
  // Für Production durch ein offizielles Google-Asset ersetzen.
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
// Divider + Footer
// ═════════════════════════════════════════════════════════════════════

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider(color: _K.line, height: 1)),
      const SizedBox(width: 12),
      Text('ODER', style: _K.mono(9, color: _K.dim, letterSpacing: 1.8)),
      const SizedBox(width: 12),
      const Expanded(child: Divider(color: _K.line, height: 1)),
    ]);
  }
}

class _FooterSwap extends StatelessWidget {
  const _FooterSwap({
    required this.lead,
    required this.action,
    required this.onTap,
  });
  final String lead, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: _K.body(13.5, color: _K.muted),
          children: [
            TextSpan(text: '$lead  '),
            TextSpan(
              text: action,
              style: _K
                  .body(13.5, color: _K.fg, weight: FontWeight.w600)
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ],
        ),
      ),
    );
  }
}
