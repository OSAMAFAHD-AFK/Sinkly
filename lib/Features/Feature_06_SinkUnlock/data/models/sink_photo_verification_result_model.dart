import 'package:equatable/equatable.dart';

/// Outcome of checking the clean-sink photo.
class SinkPhotoVerificationResultModel extends Equatable {
  const SinkPhotoVerificationResultModel({required this.isClean, required this.confidence, this.reasonKey});

  final bool isClean;

  /// 0 … 1 score from the vision model.
  final double confidence;

  /// Translation key explaining a rejection (e.g. "dishes still visible").
  final String? reasonKey;

  factory SinkPhotoVerificationResultModel.fromJson(Map<String, dynamic> json) => SinkPhotoVerificationResultModel(
    isClean: json['isClean'] as bool? ?? false,
    confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    reasonKey: json['reasonKey'] as String?,
  );

  @override
  List<Object?> get props => [isClean, confidence, reasonKey];
}
