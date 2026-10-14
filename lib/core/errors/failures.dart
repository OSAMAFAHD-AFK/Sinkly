import 'package:dio/dio.dart';

/// Base failure returned through `Either<Failure, T>` from every repo.
/// The UI only ever receives a translation key in [messageKey] so failures can
/// be shown in any of the supported languages.
abstract class Failure {
  const Failure(this.messageKey, {this.debugMessage});

  /// Localization key displayed to the user (see assets/translations/en.json).
  final String messageKey;

  /// Raw technical detail for logs — never shown to users.
  final String? debugMessage;

  @override
  String toString() => '$runtimeType($messageKey${debugMessage == null ? '' : ', $debugMessage'})';
}

/// Remote / network errors (Firebase, REST, AI verification API...).
class ServerFailure extends Failure {
  const ServerFailure(super.messageKey, {super.debugMessage});

  factory ServerFailure.fromDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ServerFailure('error_timeout', debugMessage: exception.message);
      case DioExceptionType.connectionError:
        return ServerFailure('error_no_internet', debugMessage: exception.message);
      case DioExceptionType.cancel:
        return ServerFailure('error_cancelled', debugMessage: exception.message);
      case DioExceptionType.badResponse:
        return ServerFailure('error_server', debugMessage: 'HTTP ${exception.response?.statusCode}');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ServerFailure('error_generic', debugMessage: exception.message);
    }
  }
}

/// Local persistence errors (SharedPreferences / secure storage).
class CacheFailure extends Failure {
  const CacheFailure(super.messageKey, {super.debugMessage});
}

/// In-app purchase / subscription errors (Adapty / RevenueCat later).
class PurchaseFailure extends Failure {
  const PurchaseFailure(super.messageKey, {super.debugMessage, this.userCancelled = false});

  /// Cancelled purchases are not real errors and should not show a message.
  final bool userCancelled;
}

/// OS permission errors (Screen Time, camera, notifications).
class PermissionFailure extends Failure {
  const PermissionFailure(super.messageKey, {super.debugMessage});
}

/// Clean-sink photo could not be verified.
class VerificationFailure extends Failure {
  const VerificationFailure(super.messageKey, {super.debugMessage});
}

/// Input validation errors raised before hitting any data source.
class ValidationFailure extends Failure {
  const ValidationFailure(super.messageKey, {super.debugMessage});
}

/// Native platform services that failed (store review, share sheet…).
class PlatformFailure extends Failure {
  const PlatformFailure(super.messageKey, {super.debugMessage});
}
