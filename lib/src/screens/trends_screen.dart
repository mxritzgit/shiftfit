import 'package:flutter/material.dart';

import '../models/shift_fit_plan.dart';
import '../models/sleep_entry.dart';
import '../services/daily_log_sync.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/common/selection_widgets.dart';
import '../widgets/shared/shiftfit_top_bar.dart';
import '../widgets/trends/combined_streak_card.dart';
import '../widgets/trends/today_snapshot_card.dart';
import '../widgets/trends/trends_widgets.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({
    super.key,
    required this.plan,
    required this.weekPlan,
    required this.dailyWaterMl,
    required this.waterGoalMl,
    required this.lastSleep,
    required this.sleepGoalMinutes,
    required this.workoutStreak,
    required this.completedTodayCount,
    required this.totalBlocksToday,
    required this.dailySteps,
    required this.stepsGoal,
    required this.dailyConsumedKcal,
    required this.kcalGoal,
    this.history = const <DailyLog>[],
    this.onSettingsPressed,
    this.onProfilePressed,
    this.profileInitial,
  });

  final ShiftFitPlan plan;
  final List<String> weekPlan;
  final int dailyWaterMl;
  final int waterGoalMl;
  final SleepEntry? lastSleep;
  final int sleepGoalMinutes;
  final int workoutStreak;
  final int completedTodayCount;
  final int totalBlocksToday;
  final int dailySteps;
  final int stepsGoal;
  final int dailyConsumedKcal;
  final int kcalGoal;

  /// Letzte ~28-30 Tage, aufsteigend sortiert (Orchestrator via
  /// DailyLogSync.loadRange(now-29d, now)). Defensiv: darf leer sein.
  final List<DailyLog> history;

  final VoidCallback? onSettingsPressed;
  final VoidCallback? onProfilePressed;
  final String? profileInitial;

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  // Aggregationsfenster fuer Verlauf + Insights. „Heute" zeigt 7-Tage-Balken
  // (Tagesfokus), „Woche" 7 Tage, „30 Tage" das volle Fenster.
  static const _range7 = '7 Tage';
  static const _range30 = '30 Tage';
  String _range = _range7;

  static const List<String> _weekdayLabels = [
    'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So',
  ];

  // --- Tages-Workout-Signal (defensiv ueber workoutCompleted) -------------
  bool _completed(DailyLog log) => log.workoutCompleted;

  /// Tages-Score 0..1 fuer einen Balken. Dokumentierte Metrik:
  ///   Workout absolviert  -> 1.0 (voller Balken, lime)
  ///   sonst gewichteter Routine-Score aus Wasser-, Schritte- und Mood-Ratio:
  ///     0.5*water + 0.35*steps + 0.15*mood   (mood 1..5 -> 0..1)
  /// So ist ein Trainingstag immer klar dominant, ruhige Tage zeigen die
  /// tatsaechliche Routine-Dichte statt eines leeren Balkens.
  double _dayScore(DailyLog log) {
    if (_completed(log)) return 1.0;
    final water = widget.waterGoalMl <= 0
        ? 0.0
        : (log.waterMl / widget.waterGoalMl).clamp(0.0, 1.0).toDouble();
    final steps = widget.stepsGoal <= 0
        ? 0.0
        : (log.steps / widget.stepsGoal).clamp(0.0, 1.0).toDouble();
    final mood = log.moodScore <= 0
        ? 0.0
        : ((log.moodScore - 1) / 4).clamp(0.0, 1.0).toDouble();
    return (0.5 * water + 0.35 * steps + 0.15 * mood).clamp(0.0, 1.0);
  }

  /// Liefert fuer jeden der letzten [days] Kalendertage genau einen Eintrag
  /// (echtes Datum), auch wenn fuer den Tag kein Log existiert (-> leerer Tag).
  List<DailyLog?> _lastDays(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final byDay = <int, DailyLog>{};
    for (final log in widget.history) {
      final d = log.date;
      byDay[_dayKey(DateTime(d.year, d.month, d.day))] = log;
    }
    final out = <DailyLog?>[];
    for (var i = days - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      out.add(byDay[_dayKey(day)]);
    }
    return out;
  }

  static int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  // --- 7-Tage-Balken aus echter History -----------------------------------
  List<TrendBar> _buildBars() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logs = _lastDays(7);
    final bars = <TrendBar>[];
    for (var i = 0; i < logs.length; i++) {
      final day = today.subtract(Duration(days: 6 - i));
      final log = logs[i];
      final isToday = day == today;
      final liveToday = isToday &&
          widget.totalBlocksToday > 0 &&
          widget.completedTodayCount >= widget.totalBlocksToday;
      final workout = (log != null && _completed(log)) || liveToday;
      final ratio = workout ? 1.0 : (log == null ? 0.0 : _dayScore(log));
      bars.add(TrendBar(
        label: _weekdayLabels[(day.weekday - 1) % 7],
        ratio: ratio,
        // Encoding: lime = Trainingstag, wellnessTone = Routine-Tag.
        color: workout ? lime : wellnessTone,
        isToday: isToday,
      ));
    }
    return bars;
  }

  // --- Readiness BERECHNET -------------------------------------------------
  // Formel (clamp 0..100):
  //   readiness = 100 * (0.40*sleep + 0.25*completion + 0.20*mood + 0.15*water)
  // sleep/water = ratio gegen Ziel; completion = Bloecke heute fertig;
  // mood = (score-1)/4. Ersetzt den statischen plan.recoveryScore-Anzeigewert;
  // das ShiftFitPlan-Modell bleibt unangetastet.
  int _readiness({
    required double sleepRatio,
    required double waterRatio,
    required double completion,
    required int moodScore,
  }) {
    final mood = moodScore <= 0 ? 0.0 : ((moodScore - 1) / 4).clamp(0.0, 1.0);
    final score = 0.40 * sleepRatio +
        0.25 * completion +
        0.20 * mood +
        0.15 * waterRatio;
    return (score * 100).round().clamp(0, 100);
  }

  /// Readiness fuer einen vergangenen History-Tag (ohne Live-Today-Signale) —
  /// nur fuer den „vs. gestern"-Delta-Vergleich.
  int _readinessForLog(DailyLog log) {
    final sleep = 0.0; // History traegt keinen Schlaf; neutral gewichtet.
    final water = widget.waterGoalMl <= 0
        ? 0.0
        : (log.waterMl / widget.waterGoalMl).clamp(0.0, 1.0).toDouble();
    final completion = _completed(log) ? 1.0 : 0.0;
    return _readiness(
      sleepRatio: sleep,
      waterRatio: water,
      completion: completion,
      moodScore: log.moodScore,
    );
  }

  // --- Insights aus echten History-Mustern ---------------------------------
  List<TrendInsight> _buildInsights() {
    final out = <TrendInsight>[];
    final last7 = _lastDays(7);
    final logged7 = last7.whereType<DailyLog>().toList();

    // 1) Workout-Luecke: aufeinanderfolgende Tage ohne Workout (vom heute/
    //    gestern rueckwaerts). Live-Today zaehlt als absolviert wenn fertig.
    final liveTodayDone = widget.totalBlocksToday > 0 &&
        widget.completedTodayCount >= widget.totalBlocksToday;
    var gap = 0;
    for (var i = last7.length - 1; i >= 0; i--) {
      final isLast = i == last7.length - 1;
      final done = (isLast && liveTodayDone) ||
          (last7[i] != null && _completed(last7[i]!));
      if (done) break;
      gap++;
    }
    if (gap >= 2) {
      out.add(TrendInsight(
        icon: Icons.bolt,
        color: warning,
        text: 'Kein Workout an den letzten $gap Tagen — heute ein kurzer Reiz hält die Streak.',
      ));
    } else if (widget.workoutStreak >= 3) {
      out.add(TrendInsight(
        icon: Icons.bolt,
        color: lime,
        text: '${widget.workoutStreak} Tage am Stück trainiert. Momentum mitnehmen, Schlaf stabil halten.',
      ));
    } else {
      out.add(const TrendInsight(
        icon: Icons.bolt,
        color: lime,
        text: 'Genug Reserve für einen sauberen Trainingsreiz heute.',
      ));
    }

    // 2) Wasser unter Ziel: an wie vielen der geloggten Tage < Ziel.
    if (logged7.isNotEmpty && widget.waterGoalMl > 0) {
      final under = logged7.where((d) => d.waterMl < widget.waterGoalMl).length;
      if (under >= 1) {
        out.add(TrendInsight(
          icon: Icons.check_circle_outline,
          color: cyan,
          text: 'Wasser an $under/${logged7.length} Tagen unter Ziel — früher am Tag starten.',
        ));
      } else {
        out.add(const TrendInsight(
          icon: Icons.check_circle_outline,
          color: cyan,
          text: 'Wasserziel zuletzt durchgehend getroffen. Stark.',
        ));
      }
    }

    // 3) Schlaf-Schnitt aus letztem Log (History traegt keine Schlafserie) —
    //    sonst Schritte-Schnitt als zweiter Routine-Hebel.
    if (widget.lastSleep != null && widget.sleepGoalMinutes > 0) {
      final mins = widget.lastSleep!.duration.inMinutes;
      final hours = (mins / 60);
      final goalH = widget.sleepGoalMinutes / 60;
      final h = hours.toStringAsFixed(1).replaceAll('.', ',');
      out.add(TrendInsight(
        icon: Icons.check_circle_outline,
        color: wellnessTone,
        text: mins >= widget.sleepGoalMinutes
            ? 'Schlaf zuletzt ${h} h — über dem Ziel. Recovery-Anker hält.'
            : 'Schlaf zuletzt ${h} h, Ziel ${goalH.toStringAsFixed(0)} h. Früher runterfahren.',
      ));
    } else if (logged7.isNotEmpty && widget.stepsGoal > 0) {
      final avg = logged7.map((d) => d.steps).fold<int>(0, (a, b) => a + b) ~/
          logged7.length;
      out.add(TrendInsight(
        icon: Icons.check_circle_outline,
        color: wellnessTone,
        text: 'Schritte-Schnitt ${_formatSteps(avg)}/Tag (Ziel ${_formatSteps(widget.stepsGoal)}).',
      ));
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    final double waterRatio = widget.waterGoalMl <= 0
        ? 0.0
        : (widget.dailyWaterMl / widget.waterGoalMl).clamp(0.0, 1.0).toDouble();
    final sleepMinutes = widget.lastSleep?.duration.inMinutes ?? 0;
    final double sleepRatio = widget.sleepGoalMinutes <= 0
        ? 0.0
        : (sleepMinutes / widget.sleepGoalMinutes).clamp(0.0, 1.0).toDouble();
    final double stepsRatio = widget.stepsGoal <= 0
        ? 0.0
        : (widget.dailySteps / widget.stepsGoal).clamp(0.0, 1.0).toDouble();
    final double completion = widget.totalBlocksToday <= 0
        ? 0.0
        : (widget.completedTodayCount / widget.totalBlocksToday)
            .clamp(0.0, 1.0)
            .toDouble();

    final readiness = _readiness(
      sleepRatio: sleepRatio,
      waterRatio: waterRatio,
      completion: completion,
      moodScore: _todayMoodScore(),
    );

    // „vs. gestern"-Delta fuer Readiness aus dem letzten History-Tag.
    final readinessDelta = _readinessDelta(readiness);

    final sleepLabel = widget.lastSleep == null
        ? '–'
        : '${(sleepMinutes / 60).toStringAsFixed(sleepMinutes % 60 == 0 ? 0 : 1)}h';

    final stats = <SnapshotStat>[
      SnapshotStat(
        label: 'Readiness',
        value: '$readiness%',
        color: readiness >= 70
            ? lime
            : (readiness >= 45 ? wellnessTone : warning),
        ratio: readiness / 100,
        delta: readinessDelta,
      ),
      SnapshotStat(
        label: 'Schlaf',
        value: sleepLabel,
        color: wellnessTone,
        ratio: sleepRatio,
      ),
      SnapshotStat(
        label: 'Wasser',
        value: '${(widget.dailyWaterMl / 1000).toStringAsFixed(1)}L',
        color: cyan,
        ratio: waterRatio,
      ),
      SnapshotStat(
        label: 'Schritte',
        value: _formatSteps(widget.dailySteps),
        color: lime,
        ratio: stepsRatio,
      ),
    ];

    final bars = _buildBars();
    final insights = _buildInsights();

    return Column(
      key: const ValueKey('screen-trends'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftFitTopBar(
          plan: plan,
          onSettingsPressed: widget.onSettingsPressed,
          onProfilePressed: widget.onProfilePressed,
          profileInitial: widget.profileInitial,
        ),
        const SizedBox(height: 20),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fortschritt bleibt\nsichtbar.',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Training, Recovery und Routinen auf einen Blick.',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TodaySnapshotCard(stats: stats),
        const SizedBox(height: 16),
        CombinedStreakCard(
          workoutStreak: widget.workoutStreak,
          completedToday: widget.totalBlocksToday > 0 &&
              widget.completedTodayCount >= widget.totalBlocksToday,
          history: widget.history,
        ),
        const SizedBox(height: 24),
        SectionHeader(title: 'Progress Verlauf', action: _range),
        const SizedBox(height: 12),
        SegmentedOptions(
          options: const [_range7, _range30],
          selectedValue: _range,
          onSelected: (value) => setState(() => _range = value),
        ),
        const SizedBox(height: 12),
        if (_range == _range30)
          _RangeSummaryCard(
            days: _lastDays(30),
            completed: _completed,
          )
        else
          TrendBarsCard(bars: bars),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Insights', action: ''),
        const SizedBox(height: 12),
        InsightsCard(insights: insights),
      ],
    );
  }

  int _todayMoodScore() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final log in widget.history) {
      final d = log.date;
      if (DateTime(d.year, d.month, d.day) == today) return log.moodScore;
    }
    return 0;
  }

  int _readinessDelta(int todayReadiness) {
    final now = DateTime.now();
    final yesterday =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    for (final log in widget.history) {
      final d = log.date;
      if (DateTime(d.year, d.month, d.day) == yesterday) {
        final prev = _readinessForLog(log);
        if (todayReadiness > prev) return 1;
        if (todayReadiness < prev) return -1;
        return 0;
      }
    }
    return 0;
  }

  static String _formatSteps(int steps) {
    if (steps >= 1000) {
      final k = steps / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    return '$steps';
  }
}

/// Kompakte 30-Tage-Zusammenfassung statt 30 winziger Balken: Trainingstage,
/// Schritte-Schnitt und Wasser-Trefferquote — dicht, lesbar, tabellarisch.
class _RangeSummaryCard extends StatelessWidget {
  const _RangeSummaryCard({required this.days, required this.completed});

  final List<DailyLog?> days;
  final bool Function(DailyLog) completed;

  @override
  Widget build(BuildContext context) {
    final logged = days.whereType<DailyLog>().toList();
    final workouts = logged.where(completed).length;
    final avgSteps = logged.isEmpty
        ? 0
        : logged.map((d) => d.steps).fold<int>(0, (a, b) => a + b) ~/
            logged.length;
    final daysWithData = logged.length;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              value: '$workouts',
              label: 'Workouts',
              color: lime,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryTile(
              value: _TrendsScreenState._formatSteps(avgSteps),
              label: 'Ø Schritte',
              color: wellnessTone,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryTile(
              value: '$daysWithData',
              label: 'aktive Tage',
              color: cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
