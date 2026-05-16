import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth_repository.dart';
import '../screens/auth_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authRepository,
    required this.builder,
  });

  final AuthRepository authRepository;
  final Widget Function(BuildContext context, FitPilotUser user) builder;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<FitPilotUser?>? _subscription;
  FitPilotUser? _user;

  @override
  void initState() {
    super.initState();
    _user = widget.authRepository.currentUser;
    _subscription = widget.authRepository.authStateChanges.listen((user) {
      if (!mounted) return;
      setState(() => _user = user);
    });
  }

  @override
  void didUpdateWidget(covariant AuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authRepository == widget.authRepository) return;
    _subscription?.cancel();
    _user = widget.authRepository.currentUser;
    _subscription = widget.authRepository.authStateChanges.listen((user) {
      if (!mounted) return;
      setState(() => _user = user);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return AuthScreen(authRepository: widget.authRepository);
    }
    return widget.builder(context, user);
  }
}
