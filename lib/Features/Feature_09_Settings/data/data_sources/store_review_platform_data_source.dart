import 'package:in_app_review/in_app_review.dart';

import '../../../../core/utils/app_constants.dart';

/// How a "Rate Sinkly" tap was handled.
enum StoreReviewOutcome {
  /// The store's "write a review" page was opened.
  storePage,

  /// It couldn't be opened (no store app / no browser).
  unavailable,
}

/// App-store rating, the way Apple and Google ask for it:
///
///  * [requestNativeReview] — the in-app rating sheet (Apple
///    SKStoreReviewController / Google Play In-App Review) for an automatic
///    moment in the flow. The OS decides whether it appears (quota: Apple at
///    most 3× per 365 days; Google an undisclosed quota) and never tells the
///    app, so it must never sit behind a button.
///  * [openStoreReviewPage] — what a "Rate" button opens: the App Store's
///    write-a-review page / the Play Store listing. Always visible.
///
/// Testing: iOS shows the sheet in debug builds (submitting is disabled) but
/// never in TestFlight; Android shows it only for an install from Google Play
/// (internal testing track), never for a debug or sideloaded APK.
abstract class StoreReviewPlatformDataSource {
  Future<void> requestNativeReview();

  Future<StoreReviewOutcome> openStoreReviewPage();
}

class InAppReviewStoreReviewDataSource implements StoreReviewPlatformDataSource {
  InAppReviewStoreReviewDataSource([InAppReview? inAppReview]) : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  @override
  Future<void> requestNativeReview() async {
    if (await _inAppReview.isAvailable()) await _inAppReview.requestReview();
  }

  @override
  Future<StoreReviewOutcome> openStoreReviewPage() async {
    try {
      // iOS: the App Store's write-a-review page (needs the Apple ID).
      // Android: the Play Store listing of this package.
      await _inAppReview.openStoreListing(appStoreId: AppConstants.appStoreId);
      return StoreReviewOutcome.storePage;
    } catch (_) {
      return StoreReviewOutcome.unavailable;
    }
  }
}
