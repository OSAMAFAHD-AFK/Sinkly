import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/app_constants.dart';

/// Opens the camera to snap the clean sink.
///
/// Debug builds fall back to the photo library on simulators without a
/// camera. Release builds never do: an old or downloaded picture must not be
/// able to unlock the apps.
abstract class SinkPhotoCaptureDataSource {
  /// Returns the local file path, or `null` if the user cancelled.
  Future<String?> captureSinkPhoto();
}

class SinkPhotoCaptureDataSourceImpl implements SinkPhotoCaptureDataSource {
  SinkPhotoCaptureDataSourceImpl(this._picker);

  final ImagePicker _picker;

  @override
  Future<String?> captureSinkPhoto() async {
    // ≤1024 px JPEG (~150–300 KB): all the AI check needs, cheap and quick to upload.
    const maxSide = AppConstants.verificationPhotoMaxSide * 1.0;
    XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: 80,
      );
    } catch (_) {
      if (!kDebugMode) rethrow;
      // Debug only: no camera available (e.g. iOS simulator) → use the gallery instead.
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: 80,
      );
    }
    return file?.path;
  }
}
