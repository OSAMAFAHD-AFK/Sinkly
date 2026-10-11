import 'package:image_picker/image_picker.dart';

/// Opens the camera to snap the clean sink. Falls back to the photo library
/// on devices/simulators without a camera so the flow is always testable.
abstract class SinkPhotoCaptureDataSource {
  /// Returns the local file path, or `null` if the user cancelled.
  Future<String?> captureSinkPhoto();
}

class SinkPhotoCaptureDataSourceImpl implements SinkPhotoCaptureDataSource {
  SinkPhotoCaptureDataSourceImpl(this._picker);

  final ImagePicker _picker;

  @override
  Future<String?> captureSinkPhoto() async {
    XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        imageQuality: 72,
      );
    } catch (_) {
      // No camera available (e.g. iOS simulator) → use the gallery instead.
      file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 72);
    }
    return file?.path;
  }
}
