import 'dart:ui';

import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet (WhatsApp, Messages, Instagram DMs, …).
abstract class AppSharePlatformDataSource {
  /// `true` when the user picked a target; `false` when they dismissed it
  /// (Android can't always tell — it reports `true` once the sheet opened).
  Future<bool> shareText({required String text, required String subject, Rect? origin});
}

class SharePlusAppShareDataSource implements AppSharePlatformDataSource {
  @override
  Future<bool> shareText({required String text, required String subject, Rect? origin}) async {
    final result = await SharePlus.instance.share(
      // iPad anchors its share popover to [origin].
      ShareParams(text: text, subject: subject, sharePositionOrigin: origin),
    );
    return result.status != ShareResultStatus.dismissed;
  }
}
