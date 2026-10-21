import 'package:flutter_test/flutter_test.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/data/data_sources/sink_photo_verification_data_source.dart';

/// Store builds must never approve a photo without the photo-check backend.
void main() {
  test('the store-build photo check never approves a photo', () async {
    final result = await const UnavailableSinkPhotoVerificationDataSource().verifySinkPhoto('any.jpg');
    expect(result.isClean, isFalse);
    expect(result.reasonKey, 'verify_error_unavailable');
  });
}
