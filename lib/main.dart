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

class ShiftFitHomePage extends StatelessWidget {
  const ShiftFitHomePage({super.key});

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
            children: const [
              HeroSection(),
              SizedBox(height: 24),
              ShiftOverviewCard(),
              SizedBox(height: 16),
              DailyCheckInCard(),
              SizedBox(height: 16),
              FocusAreasCard(),
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
  const DailyCheckInCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Heute',
      subtitle: 'So könnte später dein Tages-Check-in aussehen.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.bolt_rounded, color: Color(0xFF7CFF6B)),
            title: Text('Energie: Mittel'),
            subtitle: Text('Nach zwei Frühschichten lieber kurz und sauber trainieren.'),
          ),
          const SizedBox(height: 8),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.access_time_rounded, color: Color(0xFF5BC0FF)),
            title: Text('Verfügbare Zeit: 20 Minuten'),
            subtitle: Text('Perfekt für eine kurze Ganzkörper-Session oder Mobility.'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Heutige Empfehlung starten'),
            ),
          ),
        ],
      ),
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
