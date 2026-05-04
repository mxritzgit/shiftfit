import 'package:flutter/material.dart';

import '../models/shift_fit_plan.dart';
import '../widgets/common/basic_widgets.dart';
import '../widgets/shared/shiftfit_top_bar.dart';
import '../widgets/today/today_widgets.dart';

class TodayDashboard extends StatelessWidget {
  const TodayDashboard({
    super.key,
    required this.selectedShift,
    required this.selectedEnergy,
    required this.selectedStress,
    required this.plan,
    required this.onShiftSelected,
    required this.onEnergySelected,
    required this.onStressSelected,
  });

  final String selectedShift;
  final String selectedEnergy;
  final String selectedStress;
  final ShiftFitPlan plan;
  final ValueChanged<String> onShiftSelected;
  final ValueChanged<String> onEnergySelected;
  final ValueChanged<String> onStressSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('screen-today'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftFitTopBar(plan: plan),
        const SizedBox(height: 24),
        ShiftFitHero(plan: plan),
        const SizedBox(height: 22),
        QuickCheckInCard(
          selectedShift: selectedShift,
          selectedEnergy: selectedEnergy,
          selectedStress: selectedStress,
          plan: plan,
          onShiftSelected: onShiftSelected,
          onEnergySelected: onEnergySelected,
          onStressSelected: onStressSelected,
        ),
        const SizedBox(height: 18),
        RecoveryScoreCard(plan: plan),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Dein Plan für heute',
          action: '${plan.totalMinutes} Min',
        ),
        const SizedBox(height: 12),
        DailyPlanCard(plan: plan),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Schicht-Kompass',
          action: selectedShift,
        ),
        const SizedBox(height: 12),
        ShiftTimeline(shift: selectedShift),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Recovery Tools', action: '3 Basics'),
        const SizedBox(height: 12),
        RecoveryToolsGrid(plan: plan),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Wochenrhythmus', action: 'Demo'),
        const SizedBox(height: 12),
        const RhythmWeekCard(),
      ],
    );
  }
}
