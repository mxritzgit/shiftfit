import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_profile.dart';
import '../../services/kcal_calculator.dart';
import '../../theme/app_colors.dart';

Future<SettingsResult?> showSettingsSheet(
  BuildContext context, {
  required UserProfile profile,
}) {
  return showModalBottomSheet<SettingsResult>(
    context: context,
    backgroundColor: surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _SettingsSheet(initial: profile),
  );
}

class SettingsResult {
  const SettingsResult({required this.profile, required this.resetDay});

  final UserProfile profile;
  final bool resetDay;
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({required this.initial});

  final UserProfile initial;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late final TextEditingController _weight;
  late final TextEditingController _height;
  late final TextEditingController _age;
  late final TextEditingController _steps;
  late final TextEditingController _kcal;
  late final TextEditingController _water;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late BiologicalSex _sex;
  late int _sleepGoalMinutes;
  KcalTargets? _lastSuggestion;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _weight = TextEditingController(text: p.weightKg.toString());
    _height = TextEditingController(text: p.heightCm.toString());
    _age = TextEditingController(text: p.ageYears.toString());
    _steps = TextEditingController(text: p.dailyStepsGoal.toString());
    _kcal = TextEditingController(text: p.dailyKcalGoal.toString());
    _water = TextEditingController(text: p.dailyWaterGoalMl.toString());
    _protein = TextEditingController(text: p.proteinGoalG.toString());
    _carbs = TextEditingController(text: p.carbsGoalG.toString());
    _fat = TextEditingController(text: p.fatGoalG.toString());
    _sex = p.sex;
    _sleepGoalMinutes = p.dailySleepGoalMinutes;
  }

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    _age.dispose();
    _steps.dispose();
    _kcal.dispose();
    _water.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  int _parseInt(TextEditingController c, int fallback) {
    return int.tryParse(c.text.trim()) ?? fallback;
  }

  UserProfile _buildProfile() {
    final p = widget.initial;
    return UserProfile(
      weightKg: _parseInt(_weight, p.weightKg),
      heightCm: _parseInt(_height, p.heightCm),
      ageYears: _parseInt(_age, p.ageYears),
      sex: _sex,
      dailyStepsGoal: _parseInt(_steps, p.dailyStepsGoal),
      dailyKcalGoal: _parseInt(_kcal, p.dailyKcalGoal),
      dailyWaterGoalMl: _parseInt(_water, p.dailyWaterGoalMl),
      dailySleepGoalMinutes: _sleepGoalMinutes,
      proteinGoalG: _parseInt(_protein, p.proteinGoalG),
      carbsGoalG: _parseInt(_carbs, p.carbsGoalG),
      fatGoalG: _parseInt(_fat, p.fatGoalG),
    );
  }

  void _autoCalc() {
    final draft = _buildProfile();
    final suggestion = const KcalCalculator().calculate(draft);
    setState(() {
      _kcal.text = suggestion.kcal.toString();
      _protein.text = suggestion.proteinG.toString();
      _carbs.text = suggestion.carbsG.toString();
      _fat.text = suggestion.fatG.toString();
      _lastSuggestion = suggestion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil & Ziele',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Werte fürs Auto-Tagesziel. Du kannst alles überschreiben.',
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('KÖRPER'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SettingsField(
                    label: 'Gewicht',
                    suffix: 'kg',
                    controller: _weight,
                    keyValue: const ValueKey('settings-weight'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SettingsField(
                    label: 'Größe',
                    suffix: 'cm',
                    controller: _height,
                    keyValue: const ValueKey('settings-height'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SettingsField(
                    label: 'Alter',
                    suffix: 'J.',
                    controller: _age,
                    keyValue: const ValueKey('settings-age'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SexField(
                    value: _sex,
                    onChanged: (v) => setState(() => _sex = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _SectionLabel('AKTIVITÄT'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SettingsField(
                    label: 'Schrittziel',
                    suffix: 'Schritte',
                    controller: _steps,
                    keyValue: const ValueKey('settings-steps-goal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SettingsField(
                    label: 'Wasser',
                    suffix: 'ml',
                    controller: _water,
                    keyValue: const ValueKey('settings-water'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SleepGoalField(
              minutes: _sleepGoalMinutes,
              onChanged: (v) => setState(() => _sleepGoalMinutes = v),
            ),
            const SizedBox(height: 18),
            _AutoCalcRow(suggestion: _lastSuggestion, onTap: _autoCalc),
            const SizedBox(height: 18),
            const _SectionLabel('ENERGIE & MAKROS'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SettingsField(
                    label: 'Kcal Ziel',
                    suffix: 'kcal',
                    controller: _kcal,
                    keyValue: const ValueKey('settings-kcal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SettingsField(
                    label: 'Protein',
                    suffix: 'g',
                    controller: _protein,
                    keyValue: const ValueKey('settings-protein'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SettingsField(
                    label: 'Carbs',
                    suffix: 'g',
                    controller: _carbs,
                    keyValue: const ValueKey('settings-carbs'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SettingsField(
                    label: 'Fett',
                    suffix: 'g',
                    controller: _fat,
                    keyValue: const ValueKey('settings-fat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('settings-reset-day'),
                onPressed: () => Navigator.pop(
                  context,
                  SettingsResult(profile: _buildProfile(), resetDay: true),
                ),
                icon: const Icon(Icons.restart_alt_rounded, size: 17),
                label: const Text(
                  'Tagesdaten zurücksetzen',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: orange,
                  side: BorderSide(color: orange.withValues(alpha: 0.45)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('settings-save'),
                onPressed: () => Navigator.pop(
                  context,
                  SettingsResult(profile: _buildProfile(), resetDay: false),
                ),
                icon: const Icon(Icons.check_rounded, size: 17),
                label: const Text(
                  'Speichern',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: lime,
                  foregroundColor: bg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  const _SettingsField({
    required this.label,
    required this.suffix,
    required this.controller,
    required this.keyValue,
  });

  final String label;
  final String suffix;
  final TextEditingController controller;
  final Key keyValue;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: keyValue,
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }
}

class _SexField extends StatelessWidget {
  const _SexField({required this.value, required this.onChanged});

  final BiologicalSex value;
  final ValueChanged<BiologicalSex> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('settings-sex'),
      onTap: () async {
        final picked = await showModalBottomSheet<BiologicalSex>(
          context: context,
          backgroundColor: surface,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in BiologicalSex.values)
                  ListTile(
                    key: ValueKey('settings-sex-${option.name}'),
                    title: Text(option.label),
                    trailing: value == option
                        ? const Icon(Icons.check_rounded, color: lime)
                        : null,
                    onTap: () => Navigator.pop(sheetContext, option),
                  ),
              ],
            ),
          ),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Geschlecht',
              style: TextStyle(
                color: textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepGoalField extends StatelessWidget {
  const _SleepGoalField({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    final label = '${hours}h ${rest.toString().padLeft(2, '0')}m';

    return InkWell(
      key: const ValueKey('settings-sleep-goal'),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hours, minute: rest),
          helpText: 'Schlafziel',
        );
        if (picked != null) {
          onChanged(picked.hour * 60 + picked.minute);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schlafziel',
              style: TextStyle(
                color: textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoCalcRow extends StatelessWidget {
  const _AutoCalcRow({required this.suggestion, required this.onTap});

  final KcalTargets? suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hint = suggestion == null
        ? 'Berechnet kcal + Makros aus Größe, Gewicht, Alter und Schrittziel. '
            'Verbrannt nutzt Gewicht + Größe für die tägliche Distanz.'
        : '${suggestion!.kcal} kcal · BMR ${suggestion!.bmr} · ${suggestion!.activityLabel} (×${suggestion!.activityFactor.toStringAsFixed(2)})';
    return InkWell(
      key: const ValueKey('settings-auto-calc'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: lime.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: lime.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: lime.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: lime, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Auto-berechnen',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: lime,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: lime, size: 18),
          ],
        ),
      ),
    );
  }
}
