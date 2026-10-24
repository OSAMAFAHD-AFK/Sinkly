import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sinkly/Features/Feature_06_SinkUnlock/data/data_sources/sink_photo_capture_data_source.dart';

void main() {
  late Directory cache;

  setUp(() => cache = Directory.systemTemp.createTempSync('sinkly_photo_test_'));
  tearDown(() => cache.deleteSync(recursive: true));

  File file(String name) => File('${cache.path}/$name')..writeAsBytesSync([1, 2, 3]);

  test('the photo and the camera plugin\'s other copies are deleted, nothing else', () async {
    final resized = file('scaled_image_picker_1234.jpg'); // the path the app receives
    final original = file('image_picker_1234.jpg'); // full-size original kept by the plugin
    final oldLeftover = file('image_picker_9999.jpg'); // from an earlier, interrupted check
    final somethingElse = file('flutter_cache.json');

    await SinkPhotoCaptureDataSourceImpl(ImagePicker()).discardSinkPhoto(resized.path);

    expect(resized.existsSync(), isFalse);
    expect(original.existsSync(), isFalse);
    expect(oldLeftover.existsSync(), isFalse);
    expect(somethingElse.existsSync(), isTrue);
  });

  test('a photo that is already gone is not an error', () async {
    await expectLater(
      SinkPhotoCaptureDataSourceImpl(ImagePicker()).discardSinkPhoto('${cache.path}/missing.jpg'),
      completes,
    );
  });
}
