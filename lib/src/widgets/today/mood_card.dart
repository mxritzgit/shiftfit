import 'package:flutter/material.dart';

import '../../models/daily_mood.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class MoodCard extends StatelessWidget {
  const MoodCard({
    super.key,
    required this.mood,
    required this.onMoodChanged,
    required this.onEditNote,
  });

  final DailyMood mood;
  final ValueChanged<int> onMoodChanged;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('mood-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(rControl),
                ),
                child: const Icon(
                  Icons.emoji_emotions_outlined,
                  color: cyan,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mood.isSet ? mood.label : 'Stimmung',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('mood-note-button'),
                onPressed: onEditNote,
                style: TextButton.styleFrom(
                  foregroundColor: cyan,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  mood.note.isEmpty ? 'Notiz' : 'Bearbeiten',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 1; i <= 5; i++)
                _MoodOption(
                  score: i,
                  selected: mood.score == i,
                  onTap: () => onMoodChanged(i),
                ),
            ],
          ),
          if (mood.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: surfaceSoft,
                borderRadius: BorderRadius.circular(rControl),
              ),
              child: Text(
                mood.note,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({
    required this.score,
    required this.selected,
    required this.onTap,
  });

  final int score;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mood = DailyMood(score: score);
    return InkWell(
      key: ValueKey('mood-option-$score'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(rControl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: selected ? cyan.withValues(alpha: 0.18) : surfaceSoft,
          borderRadius: BorderRadius.circular(rControl),
          border: Border.all(
            color: selected ? cyan : hairline,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          mood.emoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}

Future<String?> showMoodNoteSheet(
  BuildContext context, {
  required String initial,
}) {
  final controller = TextEditingController(text: initial);
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notiz zum Tag',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kurz festhalten, was heute lief.',
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('mood-note-input'),
              controller: controller,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Notiz'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('mood-note-save'),
                onPressed: () =>
                    Navigator.pop(sheetContext, controller.text.trim()),
                icon: const Icon(Icons.check_rounded, size: 17),
                label: const Text(
                  'Speichern',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: cyan,
                  foregroundColor: bg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(rControl),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
