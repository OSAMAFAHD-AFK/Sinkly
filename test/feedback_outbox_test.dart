import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinkly/Features/Feature_03_Feedback/data/data_sources/feedback_local_data_source.dart';
import 'package:sinkly/Features/Feature_03_Feedback/data/data_sources/feedback_remote_data_source.dart';
import 'package:sinkly/Features/Feature_03_Feedback/data/models/user_feedback_model.dart';
import 'package:sinkly/Features/Feature_03_Feedback/data/repos/feedback_repo_impl.dart';
import 'package:sinkly/core/errors/failures.dart';
import 'package:sinkly/core/utils/app_localizations.dart';
import 'package:sinkly/core/utils/local_storage_service.dart';

class _FakeRemote implements FeedbackRemoteDataSource {
  FeedbackSendError? failWith;
  final List<Map<String, dynamic>> sent = [];

  @override
  Future<void> send(Map<String, dynamic> payload) async {
    if (failWith != null) throw FeedbackSendException(failWith!);
    sent.add(payload);
  }
}

void main() {
  late FeedbackLocalDataSourceImpl local;
  late _FakeRemote remote;
  late FeedbackRepoImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService(await SharedPreferences.getInstance());
    local = FeedbackLocalDataSourceImpl(storage);
    remote = _FakeRemote();
    repo = FeedbackRepoImpl(localDataSource: local, remoteDataSource: remote, localeController: LocaleController(storage));
  });

  Future<bool> submit([String message = 'Please add a weekend-only lock mode']) async =>
      (await repo.submitFeedback(category: FeedbackCategory.newFeature, message: message)).isRight();

  test('online: idea is delivered and leaves the outbox', () async {
    expect(await submit(), isTrue);
    expect(remote.sent.single['message'], 'Please add a weekend-only lock mode');
    expect(local.pendingFeedbackPayloads(), isEmpty);
  });

  test('offline: idea is kept and sent on the next flush', () async {
    remote.failWith = FeedbackSendError.unavailable;
    expect(await submit(), isTrue); // saved locally = success for the user
    expect(local.pendingFeedbackPayloads(), hasLength(1));

    remote.failWith = null;
    await repo.flushPending();
    expect(remote.sent, hasLength(1));
    expect(local.pendingFeedbackPayloads(), isEmpty);
  });

  test('rejected by the server: dropped instead of retried forever', () async {
    remote.failWith = FeedbackSendError.rejected;
    await submit();
    expect(local.pendingFeedbackPayloads(), isEmpty);
  });

  test('6th idea within 24 h is refused before saving', () async {
    for (var i = 0; i < 5; i++) {
      expect(await submit(), isTrue);
    }
    final sixth = await repo.submitFeedback(category: FeedbackCategory.bugReport, message: 'One more idea for you');
    expect(sixth.fold((failure) => failure, (_) => null), isA<ValidationFailure>());
    expect(sixth.fold((failure) => failure.messageKey, (_) => ''), 'feedback_error_daily_limit');
    expect(remote.sent, hasLength(5));
  });

  test('too-short message is refused', () async {
    expect(await submit('short'), isFalse);
  });
}
