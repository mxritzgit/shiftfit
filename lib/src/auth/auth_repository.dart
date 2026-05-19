import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class FitPilotUser {
  const FitPilotUser({required this.id, this.email, this.displayName});

  final String id;
  final String? email;
  final String? displayName;

  String get firstName {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name.split(RegExp(r'\s+')).first;
    }
    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) {
      return mail.split('@').first;
    }
    return 'Pilot';
  }
}

enum FitPilotOAuthProvider { apple, google }

extension FitPilotOAuthProviderLabel on FitPilotOAuthProvider {
  OAuthProvider get supabaseProvider => switch (this) {
    FitPilotOAuthProvider.apple => OAuthProvider.apple,
    FitPilotOAuthProvider.google => OAuthProvider.google,
  };

  String get displayName => switch (this) {
    FitPilotOAuthProvider.apple => 'Apple',
    FitPilotOAuthProvider.google => 'Google',
  };
}

abstract class AuthRepository {
  FitPilotUser? get currentUser;
  Stream<FitPilotUser?> get authStateChanges;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> signInWithOAuth(FitPilotOAuthProvider provider);
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  FitPilotUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<FitPilotUser?> get authStateChanges async* {
    yield currentUser;
    yield* _client.auth.onAuthStateChange.map(
      (event) => _mapUser(event.session?.user),
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // emailRedirectTo landet im Confirmation-Mail-Link. Sobald der User
    // den Confirm-Button drueckt, kehrt Supabase ueber das fitpilot://
    // Deep-Link-Scheme in die App zurueck - dann ist die Session sofort
    // gueltig und der AuthGate-Stream feuert wasLoggedOut->loggedIn.
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: FitPilotSupabaseConfig.oauthRedirectUrl,
      data: {'display_name': displayName.trim()},
    );
  }

  @override
  Future<void> signInWithOAuth(FitPilotOAuthProvider provider) async {
    // inAppBrowserView oeffnet SFSafariViewController (iOS) bzw. Chrome
    // Custom Tabs (Android) - ein Sheet das ueber der App liegt und sich
    // automatisch schliesst sobald das fitpilot://login-callback/ Scheme
    // greift. Fuehlt sich an wie "in der App geblieben", waehrend die
    // Cookie- und Auth-Logik des echten System-Browsers benutzt wird.
    //
    // Wichtig: kein inAppWebView - das waere ein embedded WKWebView,
    // den Google explizit fuer OAuth blockt (Account-Hijacking-Policy
    // seit 2017).
    final launched = await _client.auth.signInWithOAuth(
      provider.supabaseProvider,
      redirectTo: FitPilotSupabaseConfig.oauthRedirectUrl,
      authScreenLaunchMode: LaunchMode.inAppBrowserView,
    );
    if (!launched) {
      throw AuthException('${provider.displayName} Login wurde abgebrochen.');
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  FitPilotUser? _mapUser(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final rawName = metadata['display_name'] ??
        metadata['full_name'] ??
        metadata['name'] ??
        metadata['user_name'];
    return FitPilotUser(
      id: user.id,
      email: user.email,
      displayName: rawName is String ? rawName : null,
    );
  }
}

class PreviewAuthRepository implements AuthRepository {
  const PreviewAuthRepository();

  static const _previewUser = FitPilotUser(
    id: 'preview-user',
    email: 'moritz@example.com',
    displayName: 'Moritz',
  );

  @override
  FitPilotUser? get currentUser => _previewUser;

  @override
  Stream<FitPilotUser?> get authStateChanges async* {
    yield _previewUser;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {}

  @override
  Future<void> signInWithOAuth(FitPilotOAuthProvider provider) async {}

  @override
  Future<void> signOut() async {}
}

class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({FitPilotUser? initialUser}) : _user = initialUser;

  FitPilotUser? _user;
  final StreamController<FitPilotUser?> _controller =
      StreamController<FitPilotUser?>.broadcast();

  @override
  FitPilotUser? get currentUser => _user;

  @override
  Stream<FitPilotUser?> get authStateChanges async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    _user = FitPilotUser(id: 'test-user', email: email, displayName: 'Test Pilot');
    _controller.add(_user);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _user = FitPilotUser(id: 'test-user', email: email, displayName: displayName);
    _controller.add(_user);
  }

  @override
  Future<void> signInWithOAuth(FitPilotOAuthProvider provider) async {
    _user = FitPilotUser(
      id: 'oauth-test-user',
      email: '${provider.displayName.toLowerCase()}@example.com',
      displayName: '${provider.displayName} Pilot',
    );
    _controller.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}

AuthRepository defaultAuthRepository() {
  try {
    return SupabaseAuthRepository(Supabase.instance.client);
  } catch (_) {
    return const PreviewAuthRepository();
  }
}
