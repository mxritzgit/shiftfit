class DailyMood {
  const DailyMood({required this.score, this.note = ''});

  /// 1..5, 3 = neutral.
  final int score;
  final String note;

  static const empty = DailyMood(score: 0);

  bool get isSet => score > 0;

  String get emoji => switch (score) {
        1 => '😞',
        2 => '🙁',
        3 => '😐',
        4 => '🙂',
        5 => '😄',
        _ => '·',
      };

  String get label => switch (score) {
        1 => 'Müde',
        2 => 'Mau',
        3 => 'Okay',
        4 => 'Gut',
        5 => 'Stark',
        _ => 'Wie geht\'s?',
      };
}
