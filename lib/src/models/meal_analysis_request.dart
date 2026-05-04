import 'dart:typed_data';

class MealAnalysisRequest {
  const MealAnalysisRequest({required this.imageId, this.imageBytes});

  final String imageId;
  final Uint8List? imageBytes;
}
