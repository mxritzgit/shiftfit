import 'package:flutter/material.dart';

class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color color;
}

class HabitState {
  const HabitState({this.completedIds = const <String>{}});

  final Set<String> completedIds;

  bool isDone(String id) => completedIds.contains(id);

  HabitState toggle(String id) {
    final next = {...completedIds};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    return HabitState(completedIds: next);
  }

  HabitState clear() => const HabitState();
}
