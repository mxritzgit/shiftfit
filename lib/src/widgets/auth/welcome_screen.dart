import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Soft handoff vom OAuth-Browser zurueck in die App: erst Lade-Spinner
/// waehrend ProfileSync.load() laeuft, dann Check-Icon + "Willkommen, X"
/// als Bestaetigung, dann fade out in die echte HomePage.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.firstName,
    required this.profileReady,
    required this.onComplete,
    this.celebrateLogin = false,
  });

  /// Vorname fuer die Begruessung. Faellt auf "Pilot" zurueck.
  final String firstName;

  /// Future das resolved sobald der Profil-Load durch ist.
  final Future<void> profileReady;

  /// Wird gerufen wenn die Welcome-Animation komplett durchgelaufen ist
  /// und die Page sich zur HomePage weiterklicken soll.
  final VoidCallback onComplete;

  /// True nur bei frischem Login/Register: dann spielt nach dem Load
  /// noch die Check-Icon + "Willkommen, $firstName"-Animation. Bei
  /// Session-Restore false -> direkt durchspringen sobald Daten da
  /// sind (Splash dient nur dazu Default-Flashes zu vermeiden).
  final bool celebrateLogin;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _exitController;
  bool _showCheck = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    widget.profileReady.then(_onProfileReady);
  }

  Future<void> _onProfileReady(void _) async {
    if (!mounted) return;
    if (!widget.celebrateLogin) {
      // Session-Restore: kurz ausfaden und direkt zum Home.
      await _exitController.forward();
      if (!mounted) return;
      widget.onComplete();
      return;
    }
    setState(() => _showCheck = true);
    await _checkController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _exitController.forward();
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('screen-welcome'),
      backgroundColor: bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _exitController,
          builder: (context, child) {
            final exit = _exitController.value;
            return Opacity(
              opacity: 1 - exit,
              child: Transform.translate(
                offset: Offset(0, -16 * exit),
                child: child,
              ),
            );
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Logo(showCheck: _showCheck, controller: _checkController),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  child: _showCheck
                      ? _WelcomeText(
                          key: const ValueKey('welcome-text'),
                          firstName: widget.firstName,
                        )
                      : const _LoadingHint(key: ValueKey('loading-hint')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.showCheck, required this.controller});

  final bool showCheck;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lime-Pulse hinter dem Icon.
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            width: showCheck ? 78 : 64,
            height: showCheck ? 78 : 64,
            decoration: BoxDecoration(
              color: showCheck
                  ? lime
                  : lime.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: lime.withValues(alpha: showCheck ? 0.4 : 0.15),
                  blurRadius: showCheck ? 32 : 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) {
              return FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.4, end: 1.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  ),
                  child: child,
                ),
              );
            },
            child: showCheck
                ? _AnimatedCheck(
                    key: const ValueKey('check'),
                    controller: controller,
                  )
                : const Icon(
                    Icons.bolt_rounded,
                    key: ValueKey('bolt'),
                    color: lime,
                    size: 34,
                  ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCheck extends StatelessWidget {
  const _AnimatedCheck({super.key, required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(34, 34),
          painter: _CheckPainter(progress: controller.value),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Pfad: linker tiefer Punkt -> unterer Knick -> oberer Endpunkt.
    final a = Offset(size.width * 0.20, size.height * 0.52);
    final b = Offset(size.width * 0.44, size.height * 0.72);
    final c = Offset(size.width * 0.80, size.height * 0.32);

    // Erste Haelfte: a -> b. Zweite Haelfte: b -> c.
    final t = progress.clamp(0.0, 1.0);
    final path = Path()..moveTo(a.dx, a.dy);
    if (t <= 0.5) {
      final localT = t / 0.5;
      path.lineTo(
        a.dx + (b.dx - a.dx) * localT,
        a.dy + (b.dy - a.dy) * localT,
      );
    } else {
      final localT = (t - 0.5) / 0.5;
      path
        ..lineTo(b.dx, b.dy)
        ..lineTo(
          b.dx + (c.dx - b.dx) * localT,
          b.dy + (c.dy - b.dy) * localT,
        );
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.progress != progress;
}

class _LoadingHint extends StatelessWidget {
  const _LoadingHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text(
          'FitPilot',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 14),
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: lime,
          ),
        ),
      ],
    );
  }
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText({super.key, required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Willkommen, $firstName.',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Du bist drin.',
          style: TextStyle(
            color: textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
