import 'dart:async';

import 'package:flutter/material.dart';

import '../models/shift_fit_plan.dart';
import '../theme/app_colors.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/shared/shiftfit_top_bar.dart';
import '../widgets/week/week_widgets.dart';

class WeekPlannerScreen extends StatefulWidget {
  const WeekPlannerScreen({
    super.key,
    required this.plan,
    required this.weekPlan,
    required this.onShiftChanged,
    this.onSavePlan,
    this.onSettingsPressed,
    this.onProfilePressed,
    this.profileInitial,
  });

  static const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  static const shifts = ['Kraft', 'Muskelaufbau', 'Ausdauer', 'Mobility', 'Recovery', 'Frei'];

  final ShiftFitPlan plan;
  final List<String> weekPlan;
  final void Function(int dayIndex, String shift) onShiftChanged;

  /// Optional save ritual. When provided, a lime "Plan speichern" pill is
  /// shown; tapping it triggers this callback (orchestrator persists via
  /// `sync.weeklyPlan.save(weekPlan)`) and the UI shows transient confirmation.
  final VoidCallback? onSavePlan;

  final VoidCallback? onSettingsPressed;
  final VoidCallback? onProfilePressed;
  final String? profileInitial;

  @override
  State<WeekPlannerScreen> createState() => _WeekPlannerScreenState();
}

class _WeekPlannerScreenState extends State<WeekPlannerScreen> {
  bool _showSaved = false;
  Timer? _savedTimer;

  static const _days = WeekPlannerScreen.days;
  static const _shifts = WeekPlannerScreen.shifts;

  int get _strengthDays => widget.weekPlan
      .where((shift) => shift == 'Kraft' || shift == 'Muskelaufbau')
      .length;

  int get _recoveryDays => widget.weekPlan
      .where((shift) => shift == 'Mobility' || shift == 'Recovery' || shift == 'Frei')
      .length;

  @override
  void dispose() {
    _savedTimer?.cancel();
    super.dispose();
  }

  void _handleSave() {
    widget.onSavePlan?.call();
    _savedTimer?.cancel();
    setState(() => _showSaved = true);
    _savedTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showSaved = false);
    });
  }

  void _openDayDetail(int dayIndex) {
    showWeekDaySheet(
      context,
      day: _days[dayIndex],
      selectedShift: widget.weekPlan[dayIndex],
      shifts: _shifts,
      onShiftChanged: (shift) {
        widget.onShiftChanged(dayIndex, shift);
        // Reflect the change in the underlying screen while the sheet is open.
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('screen-week'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftFitTopBar(
          plan: widget.plan,
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
              const StatusPill(label: 'FitnessPlan', color: cyan),
              const SizedBox(height: 16),
              const Text(
                'Trainingswoche,\nsmart geplant.',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kraft, Ausdauer und Recovery so verteilen, dass Fortschritt planbar bleibt.',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                icon: Icons.fitness_center,
                title: 'Kraft & Aufbau',
                value: '$_strengthDays Krafttage',
                color: lime,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                icon: Icons.spa_rounded,
                title: 'Regeneration',
                value: '$_recoveryDays Recovery',
                color: wellnessTone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Trainingssplit', action: 'Antippen'),
        const SizedBox(height: 10),
        for (var dayIndex = 0; dayIndex < _days.length; dayIndex++) ...[
          WeekDayPlannerRow(
            day: _days[dayIndex],
            selectedShift: widget.weekPlan[dayIndex],
            shifts: _shifts,
            onShiftChanged: (shift) {
              widget.onShiftChanged(dayIndex, shift);
              if (mounted) setState(() {});
            },
            onOpenDetail: () => _openDayDetail(dayIndex),
          ),
          if (dayIndex != _days.length - 1) const SizedBox(height: 8),
        ],
        if (widget.onSavePlan != null) ...[
          const SizedBox(height: 16),
          SavePlanBar(onSave: _handleSave, showSaved: _showSaved),
        ],
        const SizedBox(height: 22),
        const SectionHeader(title: 'Wochenbalance', action: ''),
        const SizedBox(height: 10),
        WeekVolumeCard(weekPlan: widget.weekPlan),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Planungstipps', action: ''),
        const SizedBox(height: 10),
        PlanningTipsCard(weekPlan: widget.weekPlan),
      ],
    );
  }
}
