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
        const SizedBox(height: 20),
        ShiftFitHero(plan: plan),
        const SizedBox(height: 16),
        QuickCheckInCard(
          selectedShift: selectedShift,
          selectedEnergy: selectedEnergy,
          selectedStress: selectedStress,
          plan: plan,
          onShiftSelected: onShiftSelected,
          onEnergySelected: onEnergySelected,
          onStressSelected: onStressSelected,
        ),
        const SizedBox(height: 14),
        RecoveryScoreCard(plan: plan),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Dein Plan für heute',
          action: '${plan.totalMinutes} Min',
        ),
        const SizedBox(height: 10),
        DailyPlanCard(plan: plan),
        const SizedBox(height: 22),
        SectionHeader(title: 'Schicht-Kompass', action: selectedShift),
        const SizedBox(height: 10),
        ShiftTimeline(shift: selectedShift),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Recovery Tools', action: ''),
        const SizedBox(height: 10),
        RecoveryToolsGrid(plan: plan),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Wochenrhythmus', action: ''),
        const SizedBox(height: 10),
        const RhythmWeekCard(),
      ],
    );
  }
}
