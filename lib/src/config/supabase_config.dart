import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show closeInAppWebView;

class FitPilotSupabaseConfig {
  const FitPilotSupabaseConfig._();

  static const String oauthRedirectUrl = 'fitpilot://login-callback/';

  // Build-Time-Inject via --dart-define / --dart-define-from-file.
  // Kein Default im Source — der Anon-Key war frueher hardcoded
  // und ist damit kompromittiert; siehe dart_defines.example.json.
  static const String url = String.fromEnvironment('SUPABASE_URL');

  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> initialize() async {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL und SUPABASE_ANON_KEY muessen via --dart-define '
        'gesetzt werden. Siehe dart_defines.example.json und README.md.',
      );
    }
    await Supabase.initialize(url: url, anonKey: anonKey);
    _wireOAuthSheetDismiss();
  }

  /// SFSafariViewController (iOS) / Chrome Custom Tab (Android) wissen
  /// nicht von alleine dass der OAuth-Flow durch ist - die Sheet bleibt
  /// offen bis der User sie manuell schliesst. Hier hoeren wir auf den
  /// signedIn-Event und dismissen die Sheet sobald die Session da ist.
  ///
  /// closeInAppWebView ist ein No-Op wenn gar kein in-app Browser auf
  /// ist - also unbedenklich bei Session-Restore oder Email/Password-
  /// Login (wo keine Sheet aufging).
  static void _wireOAuthSheetDismiss() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        closeInAppWebView();
      }
    });
  }
}
