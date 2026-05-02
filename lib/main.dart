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
          seedColor: const Color(0xFF7CFF6B),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF08111A),
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
  String selectedEnergy = 'Mittel';
  String selectedTime = '20 Min';
  String selectedFocus = 'Recovery';

  String get recommendation {
    if (selectedEnergy == 'Niedrig') {
      return '10 Minuten Mobility und Atemfokus';
    }
    if (selectedEnergy == 'Hoch' && selectedTime == '40 Min') {
      return '40 Minuten Krafttraining';
    }
    if (selectedFocus == 'Training') {
      return '25 Minuten Ganzkörper-Workout';
    }
    if (selectedFocus == 'Routine') {
      return '15 Minuten Reset-Routine';
    }
    return '20 Minuten Recovery Flow';
  }

  String get recommendationHint {
    if (selectedEnergy == 'Niedrig') {
      return 'Heute zählt Regeneration mehr als Intensität.';
    }
    if (selectedEnergy == 'Hoch' && selectedTime == '40 Min') {
      return 'Du hast genug Energie für eine stärkere Session.';
    }
    if (selectedFocus == 'Training') {
      return 'Kurz, effektiv und passend vor oder nach deiner Schicht.';
    }
    if (selectedFocus == 'Routine') {
      return 'Ideal, wenn du trotz Stress in Bewegung bleiben willst.';
    }
    return 'Perfekt für Tage mit Schichtstress und wenig Reserve.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF08111A),
              Color(0xFF102235),
              Color(0xFF0A1622),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const HeroSection(),
              const SizedBox(height: 24),
              const ShiftOverviewCard(),
              const SizedBox(height: 16),
              DailyCheckInCard(
                selectedEnergy: selectedEnergy,
                selectedTime: selectedTime,
                selectedFocus: selectedFocus,
                recommendation: recommendation,
                recommendationHint: recommendationHint,
                onEnergySelected: (value) {
                  setState(() {
                    selectedEnergy = value;
                  });
                },
                onTimeSelected: (value) {
                  setState(() {
                    selectedTime = value;
                  });
                },
                onFocusSelected: (value) {
                  setState(() {
                    selectedFocus = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const FocusAreasCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        color: Colors.white.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.nightlight_round, color: Color(0xFF7CFF6B), size: 28),
              SizedBox(width: 10),
              Text(
                'ShiftFit',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Fitness und Recovery für Menschen im Schichtdienst.',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Die erste Basisversion zeigt das Konzept: Schichtplan, Tages-Check-in und Fokus für Training trotz Früh-, Spät- oder Nachtschicht.',
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class ShiftOverviewCard extends StatelessWidget {
  const ShiftOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Deine Schichtwoche',
      subtitle: 'Erste Richtung für die spätere Wochenplanung.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: const [
          ShiftChip(label: 'Mo Früh', color: Color(0xFF5BC0FF)),
          ShiftChip(label: 'Di Früh', color: Color(0xFF5BC0FF)),
          ShiftChip(label: 'Mi Spät', color: Color(0xFFFFB84D)),
          ShiftChip(label: 'Do Nacht', color: Color(0xFFB388FF)),
          ShiftChip(label: 'Fr Frei', color: Color(0xFF7CFF6B)),
        ],
      ),
    );
  }
}

class DailyCheckInCard extends StatelessWidget {
  const DailyCheckInCard({
    super.key,
    required this.selectedEnergy,
    required this.selectedTime,
    required this.selectedFocus,
    required this.recommendation,
    required this.recommendationHint,
    required this.onEnergySelected,
    required this.onTimeSelected,
    required this.onFocusSelected,
  });

  final String selectedEnergy;
  final String selectedTime;
  final String selectedFocus;
  final String recommendation;
  final String recommendationHint;
  final ValueChanged<String> onEnergySelected;
  final ValueChanged<String> onTimeSelected;
  final ValueChanged<String> onFocusSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Tages-Check-in',
      subtitle: 'Wähle deine Tagesform und ShiftFit passt den Fokus an.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckInSection(
            title: 'Wie ist deine Energie?',
            options: const ['Niedrig', 'Mittel', 'Hoch'],
            selectedValue: selectedEnergy,
            onSelected: onEnergySelected,
          ),
          const SizedBox(height: 18),
          CheckInSection(
            title: 'Wie viel Zeit hast du?',
            options: const ['10 Min', '20 Min', '40 Min'],
            selectedValue: selectedTime,
            onSelected: onTimeSelected,
          ),
          const SizedBox(height: 18),
          CheckInSection(
            title: 'Was brauchst du heute am meisten?',
            options: const ['Recovery', 'Training', 'Routine'],
            selectedValue: selectedFocus,
            onSelected: onFocusSelected,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF7CFF6B).withValues(alpha: 0.10),
              border: Border.all(
                color: const Color(0xFF7CFF6B).withValues(alpha: 0.30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dein Fokus heute: $recommendation',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recommendationHint,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Check-in speichern'),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckInSection extends StatelessWidget {
  const CheckInSection({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options
              .map(
                (option) => CheckInChoiceChip(
                  key: ValueKey('$title-$option'),
                  label: option,
                  selected: option == selectedValue,
                  onSelected: () => onSelected(option),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class CheckInChoiceChip extends StatelessWidget {
  const CheckInChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final highlight = const Color(0xFF7CFF6B);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      selectedColor: highlight.withValues(alpha: 0.18),
      side: BorderSide(
        color: selected
            ? highlight.withValues(alpha: 0.36)
            : Colors.white.withValues(alpha: 0.12),
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? highlight : Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

class FocusAreasCard extends StatelessWidget {
  const FocusAreasCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'ShiftFit Fokus',
      subtitle: 'Die drei Basics, mit denen wir starten.',
      child: const Column(
        children: [
          FocusRow(
            icon: Icons.fitness_center_rounded,
            title: 'Training',
            text: 'Kurze Sessions, die zu Schicht und Energie passen.',
          ),
          SizedBox(height: 14),
          FocusRow(
            icon: Icons.hotel_rounded,
            title: 'Recovery',
            text: 'Schlaf, Erholung und Belastung nicht ignorieren.',
          ),
          SizedBox(height: 14),
          FocusRow(
            icon: Icons.restaurant_rounded,
            title: 'Routine',
            text: 'Nicht perfekt leben — sondern trotz Chaos konstant bleiben.',
          ),
        ],
      ),
    );
  }
}

class FocusRow extends StatelessWidget {
  const FocusRow({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          child: Icon(icon, color: const Color(0xFF7CFF6B)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ShiftChip extends StatelessWidget {
  const ShiftChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.07),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}
