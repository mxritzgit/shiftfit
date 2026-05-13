import 'dart:typed_data';

enum MealPortionHint {
  small('klein', '~30% weniger als Standardportion'),
  normal('normal', 'Standardportion'),
  large('groß', '~50% mehr als Standardportion'),
  extraLarge('sehr groß', '~doppelte Standardportion');

  const MealPortionHint(this.label, this.guidance);

  final String label;
  final String guidance;
}

class MealAnalysisRequest {
  const MealAnalysisRequest({
    required this.imageId,
    this.imageBytes,
    this.portionHint,
    this.freeTextHint,
  });

  final String imageId;
  final Uint8List? imageBytes;
  final MealPortionHint? portionHint;
  final String? freeTextHint;
}
