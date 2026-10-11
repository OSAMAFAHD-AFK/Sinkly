import 'dart:io';

import '../models/sink_photo_verification_result_model.dart';

/// Decides whether a photo shows a clean sink.
///
/// Production plan: upload with `ApiService.uploadFile(endPoint: 'sink/verify')`
/// to a vision model (e.g. a Claude vision prompt or an on-device classifier),
/// returning `{isClean, confidence, reasonKey}`. Also add anti-cheat checks:
/// fresh EXIF timestamp, camera-only capture, duplicate-photo hashing.
abstract class SinkPhotoVerificationDataSource {
  Future<SinkPhotoVerificationResultModel> verifySinkPhoto(String photoPath);
}

class MockSinkPhotoVerificationDataSource implements SinkPhotoVerificationDataSource {
  @override
  Future<SinkPhotoVerificationResultModel> verifySinkPhoto(String photoPath) async {
    // Lets the scanning animation play for a satisfying moment.
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    final exists = await File(photoPath).exists();
    return exists
        ? const SinkPhotoVerificationResultModel(isClean: true, confidence: 0.94)
        : const SinkPhotoVerificationResultModel(isClean: false, confidence: 0, reasonKey: 'verify_error_unreadable');
  }
}
