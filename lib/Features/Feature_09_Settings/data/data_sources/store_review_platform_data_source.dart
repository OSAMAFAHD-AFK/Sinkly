import 'package:in_app_review/in_app_review.dart';

import '../../../../core/utils/app_constants.dart';

/// How a "Rate Sinkly" request was handled.
enum StoreReviewOutcome {
  /// The native in-app rating sheet was requested (Apple SKStoreReview /
  /// Google Play In-App Review). The OS decides whether it actually shows.
  nativePrompt,

  /// The native sheet isn't available here, so the store page was opened.
  storePage,

  /// Neither is possible yet (e.g. iOS before `AppConstants.appStoreId` is set).
  unavailable,
}

/// Native app-store rating.
///
/// Platform notes (why it may "do nothing" during development):
///  * iOS shows the sheet in debug builds, but in production Apple shows it at
///    most 3× per 365 days and never tells the app whether it appeared.
///  * Android only shows it for apps installed from Google Play (internal
///    testing track works); sideloaded/debug APKs get no sheet.
abstract class StoreReviewPlatformDataSource {
  Future<StoreReviewOutcome> requestReview();
}

class InAppReviewStoreReviewDataSource implements StoreReviewPlatformDataSource {
  InAppReviewStoreReviewDataSource([InAppReview? inAppReview]) : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  @override
  Future<StoreReviewOutcome> requestReview() async {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
      return StoreReviewOutcome.nativePrompt;
    }
    // Fallback: the listing's "write a review" page. iOS needs the Apple ID;
    // Android uses the installed package name automatically.
    try {
      await _inAppReview.openStoreListing(
        appStoreId: AppConstants.appStoreId.isEmpty ? null : AppConstants.appStoreId,
      );
      return StoreReviewOutcome.storePage;
    } catch (_) {
      return StoreReviewOutcome.unavailable;
    }
  }
}
