import 'package:flutter/material.dart';

import '../../models/habit.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class HabitsCard extends StatelessWidget {
  const HabitsCard({
    super.key,
    required this.habits,
    required this.state,
    required this.onToggle,
  });

  final List<Habit> habits;
  final HabitState state;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final completed = habits.where((h) => state.isDone(h.id)).length;
    return AppCard(
      key: const ValueKey('habits-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tagesroutinen',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Text(
                '$completed / ${habits.length}',
                style: TextStyle(
                  color: completed == habits.length ? lime : textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < habits.length; i++) ...[
            _HabitRow(
              habit: habits[i],
              done: state.isDone(habits[i].id),
              onTap: () => onToggle(habits[i].id),
            ),
            if (i != habits.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.habit,
    required this.done,
    required this.onTap,
  });

  final Habit habit;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('habit-row-${habit.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: habit.color.withValues(alpha: done ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(rChip),
              ),
              child: Icon(habit.icon, color: habit.color, size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                habit.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: done ? textMuted : textPrimary,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: done ? habit.color : Colors.transparent,
                borderRadius: BorderRadius.circular(rChip),
                border: Border.all(
                  color: done ? habit.color : textMuted.withValues(alpha: 0.45),
                ),
              ),
              child: done
                  ? Icon(Icons.check_rounded, color: bg, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

const List<Habit> defaultHabits = [
  Habit(
    id: 'morning-light',
    title: '10 Min Tageslicht am Morgen',
    icon: Icons.wb_sunny_outlined,
    color: orange,
  ),
  Habit(
    id: 'mobility',
    title: '5 Min Mobility',
    icon: Icons.accessibility_new_rounded,
    color: cyan,
  ),
  Habit(
    id: 'protein',
    title: 'Protein in jeder Mahlzeit',
    icon: Icons.set_meal_outlined,
    color: lime,
  ),
  Habit(
    id: 'no-late-screens',
    title: 'Keine Screens 30 Min vor Bett',
    icon: Icons.phonelink_erase_outlined,
    color: wellnessTone,
  ),
  Habit(
    id: 'breathwork',
    title: '4-7-8 Atmung am Abend',
    icon: Icons.air,
    color: cyan,
  ),
];
