import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../models/meal_analysis_request.dart';

class MealPhotoSelection {
  const MealPhotoSelection({
    required this.request,
    required this.previewBytes,
  });

  final MealAnalysisRequest request;
  final Uint8List? previewBytes;
}

abstract class MealPhotoInput {
  Future<MealPhotoSelection?> pick(ImageSource source);
}

class DeviceMealPhotoInput implements MealPhotoInput {
  DeviceMealPhotoInput({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<MealPhotoSelection?> pick(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1400,
    );
    if (image == null) {
      return null;
    }

    Uint8List? previewBytes;
    try {
      previewBytes = await image.readAsBytes();
    } catch (_) {
      previewBytes = null;
    }

    return MealPhotoSelection(
      request: MealAnalysisRequest(
        imageId: image.path,
        imageBytes: previewBytes,
      ),
      previewBytes: previewBytes,
    );
  }
}
