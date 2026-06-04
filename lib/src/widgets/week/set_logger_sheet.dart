import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/exercise.dart';
import '../../models/workout_set.dart';
import '../../services/local_day.dart';
import '../../services/workout_progression.dart';
import '../../services/uuid.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';
import '../common/selection_widgets.dart';

/// PROD-5: Set-Logger-Sheet — eine Uebung waehlen, Gewicht + Wiederholungen
/// eintragen, mehrere Saetze anhaengen. Zeigt „letztes Mal" + PR aus der
/// reinen [WorkoutProgression]-Logik. On-Brand (dark/lime, Radius-Skala,
/// klare deutsche Copy), spiegelt das showWeekDaySheet-Muster.
///
/// Jeder eingetragene Satz wird sofort ueber [onLogSet] persistiert (der
/// Aufrufer ruft sync.workoutLog.insert(set) und fuettert ihn in die lokale
/// History). [history] sind die bereits geloggten Saetze (fuer last-time/PR).
Future<void> showSetLoggerSheet(
  BuildContext context, {
  required List<WorkoutSet> history,
  required Future<void> Function(WorkoutSet set) onLogSet,
  String? initialExerciseId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(rSheet)),
    ),
    builder: (sheetContext) {
      return _SetLoggerSheet(
        history: history,
        onLogSet: onLogSet,
        initialExerciseId: initialExerciseId,
      );
    },
  );
}

class _SetLoggerSheet extends StatefulWidget {
  const _SetLoggerSheet({
    required this.history,
    required this.onLogSet,
    this.initialExerciseId,
  });

  final List<WorkoutSet> history;
  final Future<void> Function(WorkoutSet set) onLogSet;
  final String? initialExerciseId;

  @override
  State<_SetLoggerSheet> createState() => _SetLoggerSheetState();
}

class _SetLoggerSheetState extends State<_SetLoggerSheet> {
  late String _exerciseId;
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  /// In dieser Session frisch geloggte Saetze (oben angezeigt).
  final List<WorkoutSet> _sessionSets = <WorkoutSet>[];

  /// Wachsende History (Start = uebergebene + diese Session), damit
  /// last-time/PR live mitlaufen.
  late List<WorkoutSet> _history;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _exerciseId = widget.initialExerciseId ?? exerciseLibrary.first.id;
    _history = List<WorkoutSet>.from(widget.history);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  WorkoutSet? get _lastSet =>
      WorkoutProgression.lastSetFor(_exerciseId, _history);

  PersonalRecord? get _pr =>
      WorkoutProgression.personalRecord(_exerciseId, _history);

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  Future<void> _addSet() async {
    final weight =
        double.tryParse(_weightController.text.trim().replaceAll(',', '.'));
    final reps = int.tryParse(_repsController.text.trim());
    if (weight == null || weight < 0 || reps == null || reps <= 0) {
      setState(() => _error = 'Gewicht und Wiederholungen eingeben.');
      return;
    }
    final now = DateTime.now();
    final set = WorkoutSet(
      id: uuidV4(),
      exerciseId: _exerciseId,
      weightKg: weight,
      reps: reps,
      loggedAt: now,
      localDay: localDayKey(now),
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onLogSet(set);
      if (!mounted) return;
      setState(() {
        _sessionSets.insert(0, set);
        _history = [..._history, set];
        _repsController.clear();
        // Gewicht bewusst stehen lassen — meist gleiches Gewicht naechster Satz.
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Speichern fehlgeschlagen. Nochmal versuchen.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _lastSet;
    final pr = _pr;
    final sessionVolume = WorkoutProgression.sessionVolume(_sessionSets);
    final media = MediaQuery.of(context);

    // Bound the sheet to the visible screen so the primary action (the
    // "Satz hinzufügen" button) and the input fields stay within the viewport
    // and remain hit-testable without scrolling. The long, optional content
    // (exercise picker, last/PR card, session list) scrolls above the pinned
    // action area; the action area itself never leaves the screen.
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: lime.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(rControl),
                          ),
                          child: const Icon(Icons.fitness_center_rounded,
                              color: lime, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Satz loggen',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Gewicht und Wiederholungen festhalten.',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('ÜBUNG'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final ex in exerciseLibrary)
                          ShiftChoiceChip(
                            key: ValueKey('set-exercise-${ex.id}'),
                            label: ex.name,
                            selected: ex.id == _exerciseId,
                            color: lime,
                            onTap: () => setState(() => _exerciseId = ex.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _LastAndPrCard(last: last, pr: pr, fmt: _fmt),
                    if (_sessionSets.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: FieldLabel('DIESE SESSION')),
                          Text(
                            'Volumen ${_fmt(sessionVolume)} kg',
                            style: const TextStyle(
                              color: lime,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < _sessionSets.length; i++) ...[
                        _SessionSetRow(
                          index: _sessionSets.length - i,
                          set: _sessionSets[i],
                          fmt: _fmt,
                        ),
                        if (i != _sessionSets.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _NumberField(
                          fieldKey: const ValueKey('set-weight-field'),
                          label: 'GEWICHT (KG)',
                          controller: _weightController,
                          hint: 'z. B. 60',
                          allowDecimal: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NumberField(
                          fieldKey: const ValueKey('set-reps-field'),
                          label: 'WIEDERHOLUNGEN',
                          controller: _repsController,
                          hint: 'z. B. 8',
                          allowDecimal: false,
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      key: const ValueKey('set-error'),
                      style: const TextStyle(
                        color: danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('set-add'),
                      onPressed: _saving ? null : _addSet,
                      style: FilledButton.styleFrom(
                        backgroundColor: lime,
                        foregroundColor: bg,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(rControl),
                        ),
                      ),
                      child: Text(
                        _saving ? 'Speichern …' : 'Satz hinzufügen',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      key: const ValueKey('set-done'),
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Fertig',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastAndPrCard extends StatelessWidget {
  const _LastAndPrCard({
    required this.last,
    required this.pr,
    required this.fmt,
  });

  final WorkoutSet? last;
  final PersonalRecord? pr;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(rControl),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricBlock(
              icon: Icons.history_rounded,
              label: 'Letztes Mal',
              value: last == null
                  ? '—'
                  : '${fmt(last!.weightKg)} kg × ${last!.reps}',
            ),
          ),
          Container(width: 1, height: 34, color: hairline),
          Expanded(
            child: _MetricBlock(
              icon: Icons.emoji_events_outlined,
              label: 'PR · est. 1RM',
              value: pr == null
                  ? '—'
                  : '${fmt(pr!.maxWeightKg)} kg · ${fmt(pr!.estimatedOneRepMax)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.hint,
    required this.allowDecimal,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        const SizedBox(height: 8),
        TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              allowDecimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
            ),
          ],
          style: const TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: textMuted, fontSize: 14),
            filled: true,
            fillColor: surfaceSoft,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(rControl),
              borderSide: const BorderSide(color: hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(rControl),
              borderSide: const BorderSide(color: lime),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionSetRow extends StatelessWidget {
  const _SessionSetRow({
    required this.index,
    required this.set,
    required this.fmt,
  });

  final int index;
  final WorkoutSet set;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: surfaceSoft,
        borderRadius: BorderRadius.circular(rControl),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: lime.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(rChip),
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: lime,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              Exercise.displayName(set.exerciseId),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${fmt(set.weightKg)} kg × ${set.reps}',
            style: const TextStyle(
              color: textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
