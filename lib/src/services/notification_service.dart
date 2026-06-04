import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_content_engine.dart';

/// Abstrakte Notification-Schicht (PROD-1, on-device-Retention).
///
/// Bewusst als Interface, damit Aufrufer (Onboarding/Boot/Settings) gegen eine
/// Mock-/Noop-Implementierung testen koennen, ohne die Plattform-Plugins zu
/// ziehen. Die echte Implementierung [LocalNotificationService] kapselt
/// flutter_local_notifications + timezone und plant rein lokal via
/// zonedSchedule — KEIN APNs/FCM/Server, das haelt den Gratis-Apple-Team-Status
/// und die Zero-Cost-Constraint.
abstract class NotificationService {
  /// Einmalige Initialisierung (Timezone-DB + Plugin-Init). Idempotent.
  Future<void> init();

  /// Loest den System-Permission-Dialog aus (iOS: alert/badge/sound,
  /// Android 13+: POST_NOTIFICATIONS). Liefert true, wenn erlaubt.
  Future<bool> requestPermission();

  /// Loescht alle bisher geplanten Nudges und plant [specs] neu.
  /// Aufrufer soll IMMER die volle Liste der Engine uebergeben — die alten
  /// Eintraege werden zuvor verworfen, damit nichts dupliziert/verwaist.
  Future<void> scheduleAll(List<NotificationSpec> specs);

  /// Verwirft alle geplanten/angezeigten Nudges (z.B. bei Logout oder wenn der
  /// User Erinnerungen in den Settings deaktiviert).
  Future<void> cancelAll();
}

/// No-op-Implementierung fuer Plattformen ohne lokale Notifications (Web/Test)
/// oder als sichere Default-Injection. Tut nichts, crasht nie.
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleAll(List<NotificationSpec> specs) async {}

  @override
  Future<void> cancelAll() async {}
}

/// Echte, plattform-gestuetzte Implementierung. Nur iOS/Android werden bedient;
/// auf allen anderen Plattformen no-op-pt sie hart (statt zu crashen).
class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _androidChannelId = 'fitpilot_nudges';
  static const String _androidChannelName = 'FitPilot Erinnerungen';
  static const String _androidChannelDescription =
      'Hydration, Koffein-Stopp, Schlaf-Runway und Streak-Erinnerungen.';

  bool get _supported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  @override
  Future<void> init() async {
    if (_initialized || !_supported) return;

    // Timezone-DB laden + lokale Zone setzen. zonedSchedule braucht eine
    // gesetzte local-Location, sonst wirft tz.local. Wir nehmen die vom System
    // gemeldete Zone; faellt das fehl, bleibt UTC (besser als Crash).
    tzdata.initializeTimeZones();
    try {
      final name = DateTime.now().timeZoneName;
      // timeZoneName liefert oft Abkuerzungen (CET/CEST); ein direkter
      // Location-Lookup gelingt nur bei IANA-Namen. Schlaegt er fehl, bleibt
      // der Default (UTC) — die Plan-Zeiten der Engine sind ohnehin lokale
      // Wandzeiten, die wir unten als local interpretieren.
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // UTC-Default behalten.
    }

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      // Permission NICHT beim Init erzwingen — der explizite Schritt laeuft
      // ueber requestPermission() (Onboarding-gesteuert).
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(settings: settings);

    // Android 8+ braucht einen expliziten Channel, sonst werden Nudges nicht
    // angezeigt. Idempotent — wiederholtes Anlegen ist ein no-op.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.defaultImportance,
      ),
    );

    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    await init();

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  @override
  Future<void> scheduleAll(List<NotificationSpec> specs) async {
    if (!_supported) return;
    await init();

    // Erst aufraeumen, dann neu planen — verhindert Duplikate/Waisen, wenn die
    // Engine zwischen zwei Laeufen weniger oder andere Specs liefert.
    await _plugin.cancelAll();

    final details = _details();
    final now = tz.TZDateTime.now(tz.local);
    for (final spec in specs) {
      final when = tz.TZDateTime(
        tz.local,
        spec.scheduledFor.year,
        spec.scheduledFor.month,
        spec.scheduledFor.day,
        spec.scheduledFor.hour,
        spec.scheduledFor.minute,
        spec.scheduledFor.second,
      );
      // Defensive: nie in die Vergangenheit planen (die Engine garantiert das
      // bereits, aber Plattform-zonedSchedule wuerde sonst sofort feuern).
      if (!when.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: spec.id,
        title: spec.title,
        body: spec.body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_supported) return;
    await init();
    await _plugin.cancelAll();
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return const NotificationDetails(android: android, iOS: ios);
  }
}
