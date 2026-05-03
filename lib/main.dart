import 'package:flutter/material.dart';

void main() {
  runApp(const ShiftFitApp());
}

class ShiftFitApp extends StatelessWidget {
  const ShiftFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShiftFit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9BFF67),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF080B10),
        useMaterial3: true,
      ),
      home: const ShiftFitHomePage(),
    );
  }
}

class ShiftFitHomePage extends StatefulWidget {
  const ShiftFitHomePage({super.key});

  @override
  State<ShiftFitHomePage> createState() => _ShiftFitHomePageState();
}

class _ShiftFitHomePageState extends State<ShiftFitHomePage> {
  String selectedShift = 'Früh';
  String selectedEnergy = 'Normal';

  String get recommendation {
    if (selectedEnergy == 'Müde') {
      return 'Recovery Flow';
    }
    if (selectedEnergy == 'Stark') {
      return 'Kraft Session';
    }
    if (selectedShift == 'Nacht') {
      return 'Mobility Reset';
    }
    return '20 Min Training';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF111927), Color(0xFF080B10)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShiftFitTopBar(),
                const Spacer(flex: 2),
                const ShiftFitHero(),
                const Spacer(flex: 3),
                QuickCheckInCard(
                  selectedShift: selectedShift,
                  selectedEnergy: selectedEnergy,
                  recommendation: recommendation,
                  onShiftSelected: (value) => setState(() => selectedShift = value),
                  onEnergySelected: (value) => setState(() => selectedEnergy = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ShiftFitTopBar extends StatelessWidget {
  const ShiftFitTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'ShiftFit',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: const Icon(Icons.nightlight_round, size: 20),
        ),
      ],
    );
  }
}

class ShiftFitHero extends StatelessWidget {
  const ShiftFitHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF9BFF67).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFF9BFF67).withValues(alpha: 0.24),
            ),
          ),
          child: const Text(
            'Für deinen Rhythmus',
            style: TextStyle(
              color: Color(0xFF9BFF67),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Train smart.\nRecover better.',
          style: TextStyle(
            fontSize: 48,
            height: 0.98,
            fontWeight: FontWeight.w900,
            letterSpacing: -2.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Kurze Empfehlungen passend zu deiner Schicht.',
          style: TextStyle(
            fontSize: 17,
            height: 1.35,
            color: Colors.white.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }
}

class QuickCheckInCard extends StatelessWidget {
  const QuickCheckInCard({
    super.key,
    required this.selectedShift,
    required this.selectedEnergy,
    required this.recommendation,
    required this.onShiftSelected,
    required this.onEnergySelected,
  });

  final String selectedShift;
  final String selectedEnergy;
  final String recommendation;
  final ValueChanged<String> onShiftSelected;
  final ValueChanged<String> onEnergySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Heute',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          SegmentedOptions(
            options: const ['Früh', 'Spät', 'Nacht', 'Frei'],
            selectedValue: selectedShift,
            onSelected: onShiftSelected,
          ),
          const SizedBox(height: 12),
          SegmentedOptions(
            options: const ['Müde', 'Normal', 'Stark'],
            selectedValue: selectedEnergy,
            onSelected: onEnergySelected,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  recommendation,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9BFF67),
                  foregroundColor: const Color(0xFF080B10),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ShiftFit startet bald.')),
                  );
                },
                child: const Text(
                  'Start',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SegmentedOptions extends StatelessWidget {
  const SegmentedOptions({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: OptionPill(
                key: ValueKey('option-$option'),
                label: option,
                selected: option == selectedValue,
                onTap: () => onSelected(option),
              ),
            ),
        ],
      ),
    );
  }
}

class OptionPill extends StatelessWidget {
  const OptionPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? const Color(0xFF080B10) : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
